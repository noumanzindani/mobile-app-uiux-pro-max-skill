# Finance / Banking — Common Pitfalls

> The finance-specific mistakes AI-generated and human-built money apps make most
> often, why they hurt, and the rule that prevents each. Scan this before shipping a
> money screen.

| # | Pitfall | Why it's harmful | Fix / rule |
|---|---------|------------------|-----------|
| 1 | **Single-tap "Pay/Send"** with no review step | Accidental, irreversible money movement; taps in the thumb zone are easy to trigger by mistake | Two-step compose→review→commit; commit outside thumb arc → [[FIN-013]], [[FIN-004]] |
| 2 | **Hidden fees** revealed only after charge | Top trust-killer; consumer-protection/regulatory risk | Itemize fees + dominant total before commit → [[FIN-010]] |
| 3 | **Color-only transaction status / red-green amounts** | Unreadable to color-blind users; drives overdrafts and double-pays | Text + icon + sign; grayscale-safe → [[FIN-005]], [[FIN-012]], [[FIN-015]] |
| 4 | **Proportional numerals, left-aligned amounts** | Digits reflow, columns don't scan, totals hard to compare | Tabular numerals, right-aligned → [[FIN-002]] |
| 5 | **Rendering / logging the full PAN or CVV** | PCI-DSS breach; fraud exposure | Last-4 only; re-auth-gated reveal; never log → [[FIN-009]] |
| 6 | **No app-switcher / screenshot masking** | Financial data leaks to anyone holding the device | Background privacy overlay + secure flags → [[FIN-016]] |
| 7 | **Blocking paste / autofill on password & OTP fields** | Fails WCAG 3.3.8; harms security and accessibility for no benefit | Allow paste/managers/passkeys → [[FIN-006]] |
| 8 | **No idle timeout, or abrupt logout losing input** | Account-takeover risk on unattended devices; lost work erodes trust | Timeout + warning + graceful re-auth → [[FIN-011]] |
| 9 | **Buried or missing dispute/fraud/freeze path** | Slower reporting = larger fraud loss; often legally required | Report/dispute on every transaction; prominent freeze → [[FIN-008]] |
| 10 | **Fabricated or ambiguous `$0.00` on load/error/offline** | Users panic or act on fake data | Distinct empty/loading/error/offline; "as of <time>" when stale → [[FIN-014]] |
| 11 | **Balance always exposed, no privacy toggle** | Shoulder-surfing in public spaces | One-tap hide/show, session-persistent → [[FIN-003]] |
| 12 | **Cutesy or blaming error copy** ("Oops! You messed up") | Amplifies money anxiety; hides whether funds moved | Blameless copy that answers "did money move?" + next step → [[FIN-017]] |
| 13 | **No step-up for high-risk actions** | Adding payees / raising limits / revealing cards become soft targets for takeover | Re-auth before high-risk actions → [[FIN-006]] |
| 14 | **Pending funds counted as available** without disclosure | Overdrafts and reversed-transaction surprises | Label pending; don't silently include in available → [[FIN-005]] |
| 15 | **Amounts that clip at large font sizes** | Low-vision users can't read their own balance | Amounts scale to 200% without truncation → [[FIN-002]], [[A11Y-007]] |

## Quick self-audit

Before shipping any money screen, confirm:

- [ ] Every irreversible action has a review step and a consequence-labeled commit outside the thumb arc.
- [ ] Every fee and the final total appear before the charge.
- [ ] Status and credit/debit read correctly in grayscale.
- [ ] Amounts use tabular numerals, right-aligned, and scale to 200%.
- [ ] No full PAN/CVV rendered or logged; last-4 only.
- [ ] Sensitive screens mask in app-switcher; screenshots blocked on card details.
- [ ] Paste/autofill/passkeys work on all auth fields.
- [ ] Idle timeout + re-auth on resume; step-up before high-risk actions.
- [ ] Dispute/fraud/freeze reachable from every transaction.
- [ ] Money data has honest empty/loading/error/offline states.
- [ ] Balance privacy toggle present and screen-reader-safe.
