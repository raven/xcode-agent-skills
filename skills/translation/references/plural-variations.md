# Plural Variations

Use plural variation when a string contains a **format specifier + countable noun**. The context tool provides `relevantPluralCases` for the target locale—always provide all cases.

## Decision Tree

```
Does the string contain a format specifier (%lld, %d, %@, etc.)?
├─ No → Use simple `translation`
└─ Yes → Is there a countable noun tied to that number?
    ├─ No → Use simple `translation` (number is standalone)
    └─ Yes → How many format specifier + noun pairs?
        ├─ One → Use `variationTranslation` with `topLevelVariation`
        └─ Multiple → Use `templateTranslation` with `substitutions`
```

## Translation Types

### Simple Translation

No format specifiers, or format specifiers without countable nouns.

```json
{ "translation": "Willkommen in unserer App" }
```

### Single Noun Variation

One format specifier with one noun that varies by count.

**Source**: `"Order %lld croissants"`

```json
{
  "variationTranslation": {
    "topLevelVariation": {
      "plural.one": "Order %lld croissant",
      "plural.other": "Order %lld croissants"
    }
  }
}
```

If providing an explicit `zero` case does not meaningfully improve the semantics of the translation, you may omit it.

**Critical**: Preserve the exact format specifier (`%lld`, `%1$lld`, etc.) in each variant. Only the noun changes.
**Critical**: Provide the entire variation structure, including any variations that might have translations already. You can only write the entire structure at once, and this overwrites what was there before.

### Multiple Noun Variation

Multiple format specifiers, each with a noun needing pluralization.

**Source**: `"Order %lld apples and %lld oranges"`

```json
{
  "templateTranslation": {
    "template": "Order %#@apples@ and %#@oranges@",
    "substitutions": [
      {
        "name": "apples",
        "argNum": 1,
        "formatSpecifier": "lld",
        "variants": {
          "plural.one": "%arg apple",
          "plural.other": "%arg apples"
        }
      },
      {
        "name": "oranges",
        "argNum": 2,
        "formatSpecifier": "lld",
        "variants": {
          "plural.one": "%arg orange",
          "plural.other": "%arg oranges"
        }
      }
    ]
  }
}
```

**Key points**:
- Template uses `%#@name@` to reference substitutions
- Each substitution needs `argNum` (1-indexed position) and `formatSpecifier` (without %)
- Variants use `%arg` as placeholder for the number

### Device Variations with Plurals

When source has device variations AND each contains nouns needing pluralization, vary by device first, then by plural:

```json
{
  "variationTranslation": {
    "topLevelVariation": {
      "device.iphone": "iPhone users have %#@apps@",
      "device.mac": "Mac users have %#@apps@",
      "device.other": "Users have %lld apps"
    },
    "substitutions": [
      {
        "name": "apps",
        "argNum": 1,
        "formatSpecifier": "lld",
        "variants": {
          "plural.one": "%arg app",
          "plural.other": "%arg apps"
        }
      }
    ]
  }
}
```

**Critical**: The `device.other` fallback must be a flat string with plain format specifiers — it cannot reference substitutions or be further varied.

See [references/device-variations.md](references/device-variations.md) for when to add device variations and which device keys to use.

**Critical**: If the string is varied in the source language, you MUST use the same variation technique (i.e. top-level variation vs. substitution) in the target language.

## Plural Cases by Language

Different languages require different plural cases. The context tool tells you which cases to provide.
Always check `relevantPluralCases` from the context tool—it's authoritative for the target locale.
