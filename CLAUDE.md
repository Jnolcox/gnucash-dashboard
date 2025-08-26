# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a GnuCash financial dashboard project written in Scheme. The main component is a comprehensive executive financial dashboard that provides advanced analytics and visualizations for personal finance management within GnuCash.

## Architecture

### Core Files
- `executive-dashboard.scm`: Main dashboard implementation (57k+ lines) containing 10+ analytical widgets, KPI cards, and financial metrics
- `config-user.scm`: Simple loader script that imports the main dashboard module

### Dashboard Components
The dashboard is organized into two main categories:

**KPI Cards:**
- Net Worth with growth tracking
- Monthly Expenses with trend analysis  
- Emergency Fund adequacy assessment
- Savings Rate percentage with targets

**Analytical Widgets:**
- Asset Allocation: Visual breakdown by investment type
- Liquidity Ratio: Liquid vs illiquid asset analysis
- ROI by Asset Class: Investment performance tracking
- Expense Ratio by Life Area: Spending categorization
- Expense Trend Chart: Period-over-period spending analysis
- Net Worth Velocity: Rate of wealth change tracking
- Cash Float Time: Liquidity runway analysis
- Diversification Score: Portfolio concentration risk
- Income Growth: Revenue trend analysis with comparisons
- Credit Utilization: Credit card usage and limits

## Installation and Setup

The dashboard should be saved as: `~/Library/Application Support/GnuCash/executive-dashboard.scm` (macOS path)

### Account Organization Requirements

**Credit Utilization Setup:**
- Place credit cards under "Liabilities:Credit Card"
- Add credit limits to account notes: "limit: $5000"
- Supports multiple cards with individual tracking

**Emergency Fund Setup:**
- Create an account with "Emergency" in the name
- Examples: "Emergency Fund", "Emergency Savings", "Cash:Emergency"
- Uses case-insensitive name search

**General Account Organization:**
- Investment accounts under "Assets:Investments"
- Use descriptive account names for auto-categorization
- Group related accounts under logical parents

## Theme Integration

The dashboard supports GTK theme integration:
- Enable "Use GTK theme colors" option in report settings
- Automatically reads colors from gtk-3.0.css in GnuCash config directory
- Supports gruvbox-dark and other themes using @define-color variables
- Falls back gracefully to default light theme if gtk-3.0.css not found

## Development Notes

- The codebase uses GnuCash's Scheme API extensively
- Implements quantitative finance calculations (Sharpe ratios, portfolio analysis, etc.)
- Optimized for performance with error handling for large account sets
- Responsive design that adapts to different screen sizes
- Individual widget toggle controls for customization
- Uses functional programming paradigms typical of Scheme

## Quantitative Finance Features

This dashboard implements sophisticated financial analytics including:
- Portfolio performance metrics
- Risk analysis and diversification scoring
- Liquidity analysis and cash flow projections
- Expense categorization and trend analysis
- Asset allocation and investment performance tracking

When working with this codebase, consider using the specialized `gnucash-quant-dashboard` agent for complex quantitative finance implementations or dashboard enhancements.