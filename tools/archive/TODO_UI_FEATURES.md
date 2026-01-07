# CraveTown Alpha - UI Features TODO

Based on `chain-of-thought/game_ui_flow_specification.md`

## Completed

- [x] **Title Screen & Main Menu** - NEW GAME, CONTINUE, LOAD, SETTINGS, CREDITS, QUIT
- [x] **New Game Setup Flow** - Town name, location, difficulty, population, class distribution, economic system, tutorial preference
- [x] **Keyboard Shortcuts & Help Overlay** - SPACE pause, 1-4 speed, B/C/M/A panels, H help overlay
- [x] **River/Forest Rendering** - Fixed river boundaries and forest collision detection

## In Progress

## Pending

### Core Systems

- [ ] **Save/Load System**
  - 5 save slots with metadata (town name, cycle, population, satisfaction)
  - Autosave toggle and interval setting
  - Quicksave (F5) / Quickload (F9)
  - Load autosave option

- [ ] **Settings Panel**
  - Gameplay settings (speed options, auto-pause, tutorial hints)
  - Display settings (resolution, fullscreen, UI scale, color blind mode)
  - Audio settings (master, music, SFX volumes)
  - Controls customization
  - Accessibility options

### Immigration & Population

- [ ] **Immigration System Enhancements**
  - Town Attractiveness display with class-by-class breakdown
  - Compatibility percentage calculation display
  - "What they offer" section (skills, wealth, dependents)
  - "Why they want to leave" backstory display
  - Bulk actions (Accept All Compatible, Reject All Low)
  - Auto-Accept toggle
  - Immigration Policy settings (Open Borders, Selective, Restrictive, Closed)
  - Class Preferences sliders
  - Full applicant profile modal with 49D needs breakdown

- [ ] **Emigration Warning Panel**
  - At-risk citizens display
  - Emigration risk percentage
  - Reasons for leaving
  - "Prioritize Allocation" action

### Building System

- [ ] **Build Menu Improvements**
  - Building categories (Housing, Production, Services, Infrastructure, Decorative)
  - Search functionality
  - Building images/icons in selection grid
  - Grid layout with tooltips

- [ ] **Building Detail Enhancements**
  - Building upgrade system (Level 1, 2, etc.)
  - Efficiency breakdown display
  - Lifetime production statistics
  - Building priority setting
  - Pause/Resume production toggle
  - Demolish with salvage

- [ ] **Worker Assignment Modal**
  - Skill match recommendations
  - Production impact preview
  - Current worker list
  - Available workers list with filters

### Citizens Management

- [ ] **Citizens Overview Panel**
  - Grid/list/compact view modes
  - Filter by: Class, Status, Vocation, Satisfaction
  - Sort by: Satisfaction, Name, Class, Age, Priority
  - Pagination for large populations
  - Mass Actions dropdown
  - Export Data button

- [ ] **Character Detail Modal Enhancements**
  - 49D craving expansion view
  - Commodity fatigue display (diminishing returns)
  - Possessions/durable goods section with condition
  - Consumption history log
  - Economy & Wealth section (income, expenses, savings rate)
  - Wealth rank display
  - Priority rank display
  - Emigration/Protest risk percentages
  - Actions: View Family, Relocate Housing, View Full History

### Economy & Trade

- [ ] **Inventory Panel**
  - Category filters (Food, Materials, Goods, Luxury, Durables)
  - Production/Consumption rates per item
  - Trend indicators (up/down/stable)
  - Status indicators (Surplus, Balanced, Shortage)
  - Durables "In Use" vs "Available" tracking

- [ ] **Trade System**
  - Trading partners list with relationships
  - Active trade routes display
  - Trade balance calculation
  - Start new trade interface
  - Recurring trade setup
  - Tariffs and distance display

### Analytics & Policy

- [ ] **Analytics Dashboard**
  - Overview tab
  - Satisfaction tab with distribution charts
  - Economy tab
  - Production tab
  - Demographics tab
  - Satisfaction trends over time (charts)
  - Key insights/recommendations
  - Set Alerts functionality
  - Compare to Last Week

- [ ] **Allocation Policy Panel**
  - Economic model selection (Communist/Mixed/Market)
  - Priority mode selection (Need-Based/Balanced/Egalitarian)
  - Class weights sliders
  - History penalty slider
  - Critical threshold setting
  - Budget per class settings
  - Quick presets
  - Priority preview

- [ ] **Governance Panel**
  - Government type display/selection
  - Taxation sliders (Income, Trade, Luxury)
  - Laws & Edicts system (Mandatory Work, Rationing, Free Education, Closed Borders, etc.)

### Notifications & Events

- [ ] **Notifications System**
  - Toast notifications with priority levels (Critical, Warning, Info, Success)
  - Auto-pause on critical events
  - Notification action buttons
  - Event History Modal with filters
  - Export event log to file

### Visual Enhancements

- [ ] **Visual Indicators**
  - Building status glows (green/yellow/red for production status)
  - Citizen satisfaction circles (color-coded)
  - Speech bubbles for events
  - !/? icons for alerts

- [ ] **Mini-map**
  - Clickable viewport navigation
  - Building/citizen indicators
  - Resource overlay option

### Information & Help

- [ ] **Information System Tabs**
  - Characters Reference Tab (vocations, traits, classes documentation)
  - Buildings Reference Tab
  - Mechanics Reference Tab

- [ ] **Tutorial System**
  - Step-by-step guidance for first 30-50 cycles
  - UI highlighting for tutorial steps
  - Tutorial prompts and guidance
  - Skip/dismiss options

## Future Considerations (from spec Section 15)

- [ ] Natural Resources Overlay (water, fertility, ore deposits)
- [ ] Weather System
- [ ] Seasons
- [ ] Disasters (fire, plague, drought)
- [ ] Religion/Spirituality system
- [ ] Crime & Security
- [ ] Education System
- [ ] Healthcare
- [ ] Family & Reproduction (births, deaths, family trees)
- [ ] Social Events (festivals, weddings, funerals)
- [ ] Technology/Research
- [ ] Achievements
- [ ] Scenarios/Challenges
