"""Social service: friends, challenges, leaderboards."""

from datetime import date
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.social import (
    ChallengeCreate,
    ChallengeDetail,
    ChallengeParticipantResponse,
    ChallengeResponse,
    FriendListResponse,
    LeaderboardEntryResponse,
    LeaderboardResponse,
    UserPublic,
)
from app.schemas.user import UserPublic


async def send_friend_request(
    db: AsyncSession, sender_id: UUID, receiver_id: UUID
) -> None:
    # Check not already friends or pending
    existing = await db.execute(
        text("""
            SELECT 1 FROM friendships
            WHERE (user_id_1 = :a AND user_id_2 = :b)
               OR (user_id_1 = :b AND user_id_2 = :a)
        """),
        {"a": str(sender_id), "b": str(receiver_id)},
    )
    if existing.first():
        raise ValueError("Already friends")

    pending = await db.execute(
        text("""
            SELECT 1 FROM friend_requests
            WHERE sender_id = :sender AND receiver_id = :receiver AND status = 'pending'
        """),
        {"sender": str(sender_id), "receiver": str(receiver_id)},
    )
    if pending.first():
        raise ValueError("Request already pending")

    await db.execute(
        text("""
            INSERT INTO friend_requests (id, sender_id, receiver_id)
            VALUES (:id, :sender, :receiver)
        """),
        {"id": str(UUID(bytes=__import__('os').urandom(16))), "sender": str(sender_id), "receiver": str(receiver_id)},
    )


async def accept_friend_request(
    db: AsyncSession, request_id: UUID, user_id: UUID
) -> None:
    result = await db.execute(
        text("""
            UPDATE friend_requests SET status = 'accepted', responded_at = NOW()
            WHERE id = :id AND receiver_id = :uid AND status = 'pending'
            RETURNING sender_id, receiver_id
        """),
        {"id": str(request_id), "uid": str(user_id)},
    )
    row = result.first()
    if not row:
        raise ValueError("Request not found")

    # Create friendship with canonical ordering
    uid1 = min(row.sender_id, row.receiver_id)
    uid2 = max(row.sender_id, row.receiver_id)
    await db.execute(
        text("""
            INSERT INTO friendships (user_id_1, user_id_2)
            VALUES (:a, :b) ON CONFLICT DO NOTHING
        """),
        {"a": str(uid1), "b": str(uid2)},
    )


async def get_friends(db: AsyncSession, user_id: UUID) -> FriendListResponse:
    result = await db.execute(
        text("""
            SELECT u.id, u.display_name, u.avatar_url
            FROM friendships f
            JOIN users u ON (
                (u.id = f.user_id_2 AND f.user_id_1 = :uid)
                OR (u.id = f.user_id_1 AND f.user_id_2 = :uid)
            )
            WHERE (f.user_id_1 = :uid OR f.user_id_2 = :uid)
              AND u.deleted_at IS NULL
            ORDER BY u.display_name
        """),
        {"uid": str(user_id)},
    )
    friends = [
        UserPublic(id=r.id, display_name=r.display_name, avatar_url=r.avatar_url)
        for r in result.fetchall()
    ]
    return FriendListResponse(friends=friends, count=len(friends))


async def create_challenge(
    db: AsyncSession, creator_id: UUID, data: ChallengeCreate
) -> ChallengeResponse:
    from sqlalchemy import text as sqltext

    # Create challenge
    challenge_id = UUID(bytes=__import__('os').urandom(16))
    await db.execute(
        sqltext("""
            INSERT INTO challenges (id, creator_id, title, challenge_type, target_value, start_date, end_date)
            VALUES (:id, :creator, :title, :type, :target, :start, :end)
        """),
        {
            "id": str(challenge_id),
            "creator": str(creator_id),
            "title": data.title,
            "type": data.challenge_type,
            "target": data.target_value,
            "start": data.start_date,
            "end": data.end_date,
        },
    )

    # Add creator as participant
    await db.execute(
        sqltext("""
            INSERT INTO challenge_participants (challenge_id, user_id)
            VALUES (:cid, :uid)
        """),
        {"cid": str(challenge_id), "uid": str(creator_id)},
    )

    # Add invited users
    for uid in data.invite_user_ids:
        await db.execute(
            sqltext("""
                INSERT INTO challenge_participants (challenge_id, user_id)
                VALUES (:cid, :uid) ON CONFLICT DO NOTHING
            """),
            {"cid": str(challenge_id), "uid": str(uid)},
        )

    return ChallengeResponse(
        id=challenge_id,
        creator=UserPublic(id=creator_id, display_name="", avatar_url=None),
        title=data.title,
        challenge_type=data.challenge_type,
        target_value=data.target_value,
        start_date=data.start_date,
        end_date=data.end_date,
        status="active",
        created_at=None,
        participant_count=1 + len(data.invite_user_ids),
    )


async def get_leaderboard(
    db: AsyncSession,
    user_id: UUID,
    period_type: str,
    period_start: date,
) -> LeaderboardResponse:
    # Get friends for is_friend flag
    friends_result = await db.execute(
        text("""
            SELECT CASE
                WHEN user_id_1 = :uid THEN user_id_2
                ELSE user_id_1
            END as friend_id
            FROM friendships
            WHERE user_id_1 = :uid OR user_id_2 = :uid
        """),
        {"uid": str(user_id)},
    )
    friend_ids = {r.friend_id for r in friends_result.fetchall()}
    friend_ids.add(user_id)

    # Get leaderboard entries
    result = await db.execute(
        text("""
            SELECT l.user_id, l.total_steps, u.display_name, u.avatar_url
            FROM leaderboard_entries l
            JOIN users u ON u.id = l.user_id
            WHERE l.period_type = :pt
              AND l.period_start = :ps
              AND l.user_id = ANY(:uids)
            ORDER BY l.total_steps DESC
        """),
        {"pt": period_type, "ps": period_start, "uids": [str(uid) for uid in friend_ids]},
    )

    entries = []
    my_rank = None
    my_steps = None
    for i, row in enumerate(result.fetchall(), 1):
        entries.append(LeaderboardEntryResponse(
            rank=i,
            user=UserPublic(id=row.user_id, display_name=row.display_name, avatar_url=row.avatar_url),
            total_steps=row.total_steps,
            is_friend=row.user_id in friend_ids and row.user_id != user_id,
        ))
        if row.user_id == user_id:
            my_rank = i
            my_steps = row.total_steps

    return LeaderboardResponse(
        period_type=period_type,
        period_start=period_start,
        entries=entries,
        my_rank=my_rank,
        my_total_steps=my_steps,
    )
