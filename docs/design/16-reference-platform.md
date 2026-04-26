
# 9social — Reference Platform and Portability

## Purpose

Define the role of Plan 9 / 9front as the reference platform for 9social, and clarify how portability to other systems should emerge from the design.

---

## Core Principle

> 9social is designed for Plan 9, but not limited to Plan 9.

Plan 9 / 9front is the **reference environment** for the system.  
Other platforms are free to implement compatible clients.

---

## Why Plan 9?

Plan 9 encourages a set of design constraints that align strongly with 9social:

- Plain text data formats
- Filesystem as the primary interface
- Small, composable tools
- Minimal hidden state
- Clear separation between data and behavior

By designing within these constraints, the system remains:
- simple
- transparent
- easy to reason about

---

## Design Rule

All core features of 9social must be:

- implementable using Plan 9 tools and conventions
- expressible using plain files and directories
- independent of heavyweight frameworks or services

---

## What This Means in Practice

### 1. Protocol simplicity

The 9social data model must remain:

- text-based
- filesystem-oriented
- easy to parse without specialized libraries

Example:

- feeds are directories
- posts are text files
- metadata is simple key-value pairs

---

### 2. No required platform dependencies

The system must not require:

- GUI frameworks
- web servers
- centralized services
- non-standard runtime environments

---

### 3. Command-oriented design

Core functionality is exposed through simple commands:

```sh
9social/follow
9social/refresh
9social/timeline
9social/new-post
```

These commands operate directly on files and directories.

---

### 4. ACME as a reference UI

The primary user interface model is based on ACME:

* text-driven interaction
* commands triggered from tags
* cursor-based selection

This provides a minimal and expressive UI baseline.

---

## Portability

Because of its simplicity, 9social is inherently portable.

Other platforms can implement clients that:

* read feed repositories
* parse post files
* render timelines
* publish new posts

Possible implementations include:

* terminal clients (Linux, macOS)
* desktop GUI applications
* web-based readers
* mobile applications

---

## Compatibility Requirement

All clients must operate on the same underlying data model:

* feed structure
* post format
* profile format

No client should introduce incompatible extensions that break the core protocol.

---

## Freedom Above the Core

While the core must remain simple, higher-level clients may add:

* richer user interfaces
* search capabilities
* caching and indexing
* visualization features

These enhancements must not change the underlying feed format.

---

## Design Constraint

> If a feature cannot be implemented cleanly on Plan 9, it should not be part of the core system.

This constraint helps prevent:

* unnecessary complexity
* hidden dependencies
* protocol drift

---

## Benefits

This approach provides:

### 1. Simplicity

A small, understandable system that can be implemented by individuals.

---

### 2. Longevity

Plain text and simple structures are durable over time.

---

### 3. Interoperability

Multiple independent clients can coexist and interoperate.

---

### 4. Decentralization

No platform is privileged or required.

---

## Summary

* Plan 9 is the reference environment
* simplicity is enforced by design constraints
* portability emerges naturally from the data model

> Designed on Plan 9, usable anywhere.

