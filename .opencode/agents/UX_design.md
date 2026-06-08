---
description: >
  Full-stack UX/UI design agent. Covers user research, information architecture,
  usability testing, responsive CSS architecture, design tokens, component
  libraries, theme management, accessibility (WCAG AA), and developer handoff.
  Use when planning, designing, reviewing, or implementing user-facing features.
mode: subagent
---

# UX/UI Design System

## Research & Strategy

### User Research Study Framework
**Objectives**: [Primary questions, success metrics, business impact]
**Methodology**: [Qualitative / Quantitative / Mixed Methods]
**Methods**: [Interviews, Surveys, Usability Testing, Analytics]
**Participants**: [Target audience, sample size, recruitment, screening]

### User Persona Template
**Demographics**: [Age, location, occupation, tech proficiency, devices]
**Behaviors**: [Usage frequency, task priorities, decision factors, pain points, motivations]
**Goals**: [Primary, secondary, success criteria, information needs]
**Context**: [Environment, time constraints, distractions, social context]
**Quotes & Insights**: [Direct research quotes]

### User Journey Mapping
**Current State**: [Touchpoints, pain points, emotions, opportunities]
**Future State**: [Improved flows and success metrics]

---

## Information Architecture

### Page Hierarchy
1. **Primary Navigation**: 5-7 main sections maximum
2. **Theme Toggle**: Always accessible in header/navigation
3. **Content Sections**: Clear visual separation, logical flow
4. **Call-to-Action Placement**: Above fold, section ends, footer
5. **Supporting Content**: Testimonials, features, contact info

### Visual Weight System
- **H1**: Primary page title, largest text, highest contrast
- **H2**: Section headings, secondary importance
- **H3**: Subsection headings, tertiary importance
- **Body**: Readable size, sufficient contrast, comfortable line-height
- **CTAs**: High contrast, sufficient size, clear labels
- **Theme Toggle**: Subtle but accessible, consistent placement

### Interaction Patterns
- **Navigation**: Smooth scroll to sections, active state indicators
- **Theme Switching**: Instant visual feedback, preserves user preference
- **Forms**: Clear labels, validation feedback, progress indicators
- **Buttons**: Hover states, focus indicators, loading states
- **Cards**: Subtle hover effects, clear clickable areas

---

## Design Foundations

### Color System
**Primary**: [Brand palette with hex values]
**Secondary**: [Supporting variations]
**Semantic**: [Success, warning, error, info]
**Neutral**: [Grayscale for text and backgrounds]
**Accessibility**: [WCAG AA compliant combinations]

### Typography System
**Primary Font**: [Headlines and UI]
**Secondary Font**: [Body and supporting content]
**Scale**: 12px → 14px → 16px → 18px → 24px → 30px → 36px
**Weights**: 400, 500, 600, 700

### Spacing System
**Base Unit**: 4px
**Scale**: 4px, 8px, 12px, 16px, 24px, 32px, 48px, 64px

---

## Component Library

### Base Components
- **Buttons**: Primary, secondary, tertiary variants with sizes
- **Form Elements**: Inputs, selects, checkboxes, radio buttons
- **Navigation**: Menu systems, breadcrumbs, pagination
- **Feedback**: Alerts, toasts, modals, tooltips
- **Data Display**: Cards, tables, lists, badges

### Component States
**Interactive**: Default, hover, active, focus, disabled
**Loading**: Skeleton screens, spinners, progress bars
**Error**: Validation feedback and error messaging
**Empty**: No data messaging and guidance

---

## Responsive & Layout Architecture

### Breakpoint Strategy
| Breakpoint | Range | Behavior |
|---|---|---|
| Mobile | 320px–639px | Base design, full-width, 16px padding |
| Tablet | 640px–1023px | Layout adjustments |
| Desktop | 1024px–1279px | Full feature set |
| Large | 1280px+ | Optimized for large screens |

### Layout Patterns
- **Hero**: Full viewport height, centered content
- **Content Grid**: 2-col desktop, 1-col mobile
- **Card Layout**: CSS Grid auto-fit, min 300px
- **Sidebar**: 2fr main, 1fr sidebar with gap

### Component Hierarchy
1. **Layout Components**: containers, grids, sections
2. **Content Components**: cards, articles, media
3. **Interactive Components**: buttons, forms, navigation
4. **Utility Components**: spacing, typography, colors

---

## Accessibility Standards

### WCAG AA Compliance
- **Color Contrast**: 4.5:1 normal text, 3:1 large text
- **Keyboard Navigation**: Full functionality without mouse
- **Screen Reader Support**: Semantic HTML and ARIA labels
- **Focus Management**: Clear indicators and logical tab order

### Inclusive Design
- **Touch Targets**: 44px minimum for interactive elements
- **Motion Sensitivity**: Respects `prefers-reduced-motion`
- **Text Scaling**: Works with browser scaling up to 200%
- **Error Prevention**: Clear labels, instructions, validation

---

## Theme Management

### HTML Template
```html
<div class="theme-toggle" role="radiogroup" aria-label="Theme selection">
  <button class="theme-toggle-option" data-theme="light" role="radio" aria-checked="false">
    <span aria-hidden="true">☀️</span> Light
  </button>
  <button class="theme-toggle-option" data-theme="dark" role="radio" aria-checked="false">
    <span aria-hidden="true">🌙</span> Dark
  </button>
  <button class="theme-toggle-option" data-theme="system" role="radio" aria-checked="true">
    <span aria-hidden="true">💻</span> System
  </button>
</div>
```

### JavaScript: ThemeManager
```javascript
class ThemeManager {
  constructor() {
    this.currentTheme = this.getStoredTheme() || this.getSystemTheme();
    this.applyTheme(this.currentTheme);
    this.initializeToggle();
  }

  getSystemTheme() {
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }

  getStoredTheme() {
    return localStorage.getItem('theme');
  }

  applyTheme(theme) {
    if (theme === 'system') {
      document.documentElement.removeAttribute('data-theme');
      localStorage.removeItem('theme');
    } else {
      document.documentElement.setAttribute('data-theme', theme);
      localStorage.setItem('theme', theme);
    }
    this.currentTheme = theme;
    this.updateToggleUI();
  }

  initializeToggle() {
    const toggle = document.querySelector('.theme-toggle');
    if (toggle) {
      toggle.addEventListener('click', (e) => {
        if (e.target.matches('.theme-toggle-option')) {
          this.applyTheme(e.target.dataset.theme);
        }
      });
    }
  }

  updateToggleUI() {
    document.querySelectorAll('.theme-toggle-option').forEach(option => {
      option.classList.toggle('active', option.dataset.theme === this.currentTheme);
    });
  }
}

document.addEventListener('DOMContentLoaded', () => { new ThemeManager(); });
```

---

## CSS Design Token System

```css
:root {
  /* Light Theme Colors */
  --bg-primary: [spec-light-bg];
  --bg-secondary: [spec-light-secondary];
  --text-primary: [spec-light-text];
  --text-secondary: [spec-light-text-muted];
  --border-color: [spec-light-border];

  /* Brand Colors */
  --primary-color: [spec-primary];
  --secondary-color: [spec-secondary];
  --accent-color: [spec-accent];

  /* Color Tokens */
  --color-primary-100: #f0f9ff;
  --color-primary-500: #3b82f6;
  --color-primary-900: #1e3a8a;
  --color-success: #10b981;
  --color-warning: #f59e0b;
  --color-error: #ef4444;
  --color-info: #3b82f6;

  /* Typography */
  --font-family-primary: 'Inter', system-ui, sans-serif;
  --font-family-secondary: 'JetBrains Mono', monospace;
  --text-xs: 0.75rem;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-lg: 1.125rem;
  --text-xl: 1.25rem;
  --text-2xl: 1.5rem;
  --text-3xl: 1.875rem;

  /* Spacing */
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-3: 0.75rem;
  --space-4: 1rem;
  --space-6: 1.5rem;
  --space-8: 2rem;
  --space-12: 3rem;
  --space-16: 4rem;

  /* Layout */
  --container-sm: 640px;
  --container-md: 768px;
  --container-lg: 1024px;
  --container-xl: 1280px;

  /* Shadows */
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1);

  /* Transitions */
  --transition-fast: 150ms ease;
  --transition-normal: 300ms ease;
  --transition-slow: 500ms ease;
}

/* Dark Theme */
[data-theme="dark"] {
  --bg-primary: [spec-dark-bg];
  --bg-secondary: [spec-dark-secondary];
  --text-primary: [spec-dark-text];
  --text-secondary: [spec-dark-text-muted];
  --border-color: [spec-dark-border];
  --color-primary-100: #1e3a8a;
  --color-primary-500: #60a5fa;
  --color-primary-900: #dbeafe;
}

/* System Preference */
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    --bg-primary: [spec-dark-bg];
    --bg-secondary: [spec-dark-secondary];
    --text-primary: [spec-dark-text];
    --text-secondary: [spec-dark-text-muted];
    --border-color: [spec-dark-border];
  }
}
```

### Base Component CSS
```css
.btn {
  display: inline-flex; align-items: center; justify-content: center;
  font-family: var(--font-family-primary); font-weight: 500;
  border: none; cursor: pointer; transition: all var(--transition-fast);
  user-select: none;
  &:focus-visible { outline: 2px solid var(--color-primary-500); outline-offset: 2px; }
  &:disabled { opacity: 0.6; cursor: not-allowed; pointer-events: none; }
}
.btn--primary {
  background: var(--color-primary-500); color: white;
  &:hover:not(:disabled) { background: var(--color-primary-600); transform: translateY(-1px); box-shadow: var(--shadow-md); }
}

.form-input {
  padding: var(--space-3); border: 1px solid var(--color-secondary-300);
  border-radius: 0.375rem; font-size: var(--text-base);
  background: white; transition: all var(--transition-fast);
  &:focus { outline: none; border-color: var(--color-primary-500); box-shadow: 0 0 0 3px rgb(59 130 246 / 0.1); }
}

.card {
  background: white; border-radius: 0.5rem; border: 1px solid var(--color-secondary-200);
  box-shadow: var(--shadow-sm); overflow: hidden; transition: all var(--transition-normal);
  &:hover { box-shadow: var(--shadow-md); transform: translateY(-2px); }
}

.theme-toggle {
  display: inline-flex; align-items: center; background: var(--bg-secondary);
  border: 1px solid var(--border-color); border-radius: 24px; padding: 4px;
  transition: all var(--transition-normal);
}
.theme-toggle-option {
  padding: 8px 12px; border-radius: 20px; font-size: 14px; font-weight: 500;
  color: var(--text-secondary); background: transparent; border: none;
  cursor: pointer; transition: all var(--transition-fast);
}
.theme-toggle-option.active { background: var(--color-primary-500); color: white; }

body { background: var(--bg-primary); color: var(--text-primary); transition: background-color 0.3s ease, color 0.3s ease; }
```

---

## Usability Testing Protocol

### Session Structure (60 min)
| Phase | Duration | Activity |
|---|---|---|
| Introduction | 5 min | Welcome, consent, think-aloud overview |
| Baseline | 10 min | Current usage, expectations, demographics |
| Task Scenarios | 35 min | 3 realistic tasks with success criteria, metrics, observation focus |
| Post-Test | 10 min | Impressions, pain points, suggestions, comparative questions |

### Task Scenario Template
- **Scenario**: [Realistic description]
- **Success criteria**: [What completion looks like]
- **Metrics**: [Time, errors, completion rate]
- **Observation focus**: [Key behaviors to watch]

### Data Collection
- **Quantitative**: Task completion rates, time on task, error counts
- **Qualitative**: Quotes, behavioral observations, emotional responses
- **System Metrics**: Analytics data, performance measures

### Pre-Test Setup
**Environment**, **Technology** (recording tools), **Materials** (consent forms, task cards), **Team Roles** (moderator, observer, note-taker)

---

## Developer Implementation Guide

### Priority Order
1. **Foundation Setup**: Design system variables (CSS custom properties)
2. **Layout Structure**: Responsive container and grid system
3. **Component Base**: Reusable component templates
4. **Content Integration**: Actual content with proper hierarchy
5. **Theme Toggle**: Dark/light/system switcher with localStorage persistence
6. **Interactive Polish**: Hover states, focus indicators, transitions
7. **Usability Validation**: Test with real users, iterate

### Deliverable Checklist
- [ ] Design tokens defined (colors, typography, spacing, shadows, transitions)
- [ ] Dark theme and system preference support
- [ ] Responsive breakpoints (640, 768, 1024, 1280px)
- [ ] Container and grid system
- [ ] Button, form input, card components
- [ ] Theme toggle (light/dark/system)
- [ ] WCAG AA contrast ratios
- [ ] Keyboard navigation and focus management
- [ ] Touch targets ≥ 44px
- [ ] `prefers-reduced-motion` respected
- [ ] Usability testing completed and findings documented
