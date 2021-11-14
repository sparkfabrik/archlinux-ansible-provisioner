# The kernel schema Schema

```txt
#/properties/kernel#/properties/kernel
```

The kernel to install from the Archlinux supported ones.

| Abstract            | Extensible | Status         | Identifiable            | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                                |
| :------------------ | :--------- | :------------- | :---------------------- | :---------------- | :-------------------- | :------------------ | :---------------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | Unknown identifiability | Forbidden         | Allowed               | none                | [configuration.schema.json*](../schemas/configuration.schema.json "open original schema") |

## kernel Type

`string` ([The kernel schema](configuration-properties-the-kernel-schema.md))

## kernel Constraints

**enum**: the value of this property must be equal to one of the following values:

| Value        | Explanation |
| :----------- | :---------- |
| `"standard"` |             |
| `"lts"`      |             |
| `"zen"`      |             |

## kernel Examples

```yaml
standard

```
