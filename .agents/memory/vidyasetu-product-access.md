---
name: VidyaSetu product and access model
description: Product audience, foundational-learning scope, and safe role provisioning.
---

VidyaSetu serves students in under-resourced rural and semi-urban government schools, focusing on foundational reading, writing, and basic math. Keep the UI simple in English and ready for Hindi and Telugu.

**Why:** the user specified this audience, learning goal, and language scope.

**How to apply:** prioritize low-bandwidth, mobile-friendly workflows and keep language resources easy to extend.

New Supabase accounts default to the parent role. Only an administrator can assign a different role or school; do not add self-service role escalation.

**Why:** allowing users to assign their own roles could expose school data or administrative actions.

**How to apply:** preserve administrator-only role and school assignment in future auth and profile changes.
