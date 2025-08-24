# Podcast Advertising and Revenue Sharing Platform

A decentralized platform built on Stacks blockchain for managing podcast advertising, audience analytics, and automated revenue distribution.

## System Architecture

The platform consists of five interconnected smart contracts:

### 1. Podcast Registry (`podcast-registry.clar`)
- Manages podcast registration and metadata
- Tracks podcast ownership and verification status
- Handles podcast categorization and discovery

### 2. Advertiser Management (`advertiser-management.clar`)
- Manages advertiser accounts and campaigns
- Handles ad content storage and brand safety requirements
- Tracks advertiser budgets and spending limits

### 3. Ad Insertion Engine (`ad-insertion.clar`)
- Automates ad placement based on listener demographics
- Manages ad scheduling and frequency capping
- Tracks ad performance metrics and engagement

### 4. Revenue Distribution (`revenue-distribution.clar`)
- Calculates and distributes revenue between stakeholders
- Handles automated payments to podcasters and platform
- Manages revenue sharing percentages and fee structures

### 5. Analytics Tracker (`analytics-tracker.clar`)
- Tracks listener demographics and engagement metrics
- Monitors cross-platform audience insights
- Provides performance analytics for advertisers and podcasters

## Key Features

- **Decentralized Governance**: Community-driven platform decisions
- **Automated Revenue Sharing**: Smart contract-based payment distribution
- **Real-time Analytics**: Comprehensive audience and performance tracking
- **Brand Safety**: Content moderation and advertiser protection
- **Cross-platform Integration**: Support for multiple podcast platforms

## Data Types

### Podcast
- `podcast-id`: Unique identifier
- `owner`: Principal address of podcast owner
- `title`: Podcast title
- `category`: Content category
- `verified`: Verification status
- `total-listeners`: Cumulative listener count

### Advertisement
- `ad-id`: Unique identifier
- `advertiser`: Principal address of advertiser
- `content-hash`: IPFS hash of ad content
- `target-demographics`: Audience targeting criteria
- `budget`: Total campaign budget
- `active`: Campaign status

### Revenue Record
- `podcast-id`: Associated podcast
- `ad-id`: Associated advertisement
- `amount`: Revenue amount in microSTX
- `timestamp`: Distribution timestamp
- `podcaster-share`: Podcaster's revenue percentage

## Getting Started

1. Deploy contracts to Stacks testnet/mainnet
2. Register podcasts using `podcast-registry`
3. Set up advertiser accounts via `advertiser-management`
4. Configure ad campaigns and targeting
5. Monitor analytics and revenue distribution
