---
title: Regression Checklist
created: 2026-03-19
updated: 2026-03-19
version: 1.0
author: claude-code
---

# Regression Checklist

Manual regression checklist for each release. Run before every build submission.

## Critical Flows

### App Launch
- [ ] App launches without crash
- [ ] Bootstrap completes (all modules register)
- [ ] Root window renders at correct size
- [ ] No console errors on launch

### Project Management
- [ ] Create new project
- [ ] Switch between projects (state resets correctly)
- [ ] Edit project details
- [ ] Delete project (soft delete, data preserved)
- [ ] Empty project shows correct empty states

### Planning
- [ ] Create milestone
- [ ] Create task linked to milestone
- [ ] Change task status through full lifecycle
- [ ] Board view updates when status changes
- [ ] Timeline view renders milestones correctly
- [ ] Daily focus shows correct priority items
- [ ] Filters work in all planning views
- [ ] Search returns correct results
- [ ] Decision log entries create and display

### Dashboard
- [ ] Dashboard loads in each context mode
- [ ] Context switching updates canvas
- [ ] All widgets render without errors
- [ ] Reduced-noise mode hides low-priority widgets
- [ ] Refresh button reloads data
- [ ] Share button accessible

### Release Cockpit
- [ ] Cockpit loads for active release
- [ ] Checklist items toggle
- [ ] Blockers add and resolve
- [ ] Readiness score updates live
- [ ] Export Markdown works
- [ ] Export PDF works
- [ ] Share works
- [ ] Empty cockpit (no release) shows correct state

### GitHub Integration
- [ ] Connect to GitHub
- [ ] Fetch repositories
- [ ] Link repo to project
- [ ] Fetch issues, milestones, PRs
- [ ] Disconnect gracefully
- [ ] Reconnect after disconnect

### App Store Connect Integration
- [ ] Connect to ASC
- [ ] View build list
- [ ] View app metadata
- [ ] Disconnect gracefully
- [ ] Reconnect after disconnect

### Insights & Alerts
- [ ] Rule engine generates insights
- [ ] Health score displays correctly
- [ ] Alerts appear in notification center
- [ ] Alert dismissal works
- [ ] Filter by severity and type

### Analytics
- [ ] Events fire on key actions
- [ ] Dashboard shows aggregated data
- [ ] Period picker changes range
- [ ] Toggle analytics on/off

### Settings
- [ ] All tabs load without errors
- [ ] AI model dropdown populates
- [ ] Settings persist after restart
- [ ] Debug tools functional

### Export & Sharing
- [ ] Roadmap export (Markdown + PDF)
- [ ] Release export (Markdown + PDF)
- [ ] Insights export (Markdown + PDF)
- [ ] Project summary export
- [ ] Share sheet presents correctly

## Edge Cases

### Empty States
- [ ] New project with zero data
- [ ] Dashboard with no milestones
- [ ] Planning with no tasks
- [ ] Cockpit with no active release
- [ ] Insights with no rules triggered
- [ ] Analytics with no events

### Disconnected Services
- [ ] GitHub disconnected — no crashes
- [ ] ASC disconnected — no crashes
- [ ] AI API key missing — graceful error

### Performance
- [ ] 50+ tasks — no scroll jank
- [ ] 20+ milestones — board renders
- [ ] Rapid context switching — no lag

### Data Integrity
- [ ] Soft deletes never lose data
- [ ] Project switch resets all module state
- [ ] Concurrent operations don't corrupt state
