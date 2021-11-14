# Archlinux provisioner variables Schema

```txt
undefined
```

The installation variables to be used in Ansible

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                               |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :--------------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [configuration.schema.json](../schemas/configuration.schema.json "open original schema") |

## Archlinux provisioner variables Type

`object` ([Archlinux provisioner variables](configuration.md))

## Archlinux provisioner variables Examples

```yaml
hostname: myarch-host
username: foobar
kernel: standard
encryption: false
enable_xorg_multitouch_gestures: false
debug: false

```

# Archlinux provisioner variables Properties

| Property                                                            | Type      | Required | Nullable       | Defined by                                                                                                                                                                                           |
| :------------------------------------------------------------------ | :-------- | :------- | :------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [hostname](#hostname)                                               | `string`  | Required | cannot be null | [Archlinux provisioner variables](configuration-properties-the-hostname-of-this-installation.md "#/properties/hostname#/properties/hostname")                                                        |
| [username](#username)                                               | `string`  | Required | cannot be null | [Archlinux provisioner variables](configuration-properties-the-username-to-create-at-the-installation.md "#/properties/username#/properties/username")                                               |
| [kernel](#kernel)                                                   | `string`  | Required | cannot be null | [Archlinux provisioner variables](configuration-properties-the-kernel-schema.md "#/properties/kernel#/properties/kernel")                                                                            |
| [encryption](#encryption)                                           | `boolean` | Optional | cannot be null | [Archlinux provisioner variables](configuration-properties-encrypt-the-system.md "#/properties/encryption#/properties/encryption")                                                                   |
| [enable_xorg_multitouch_gestures](#enable_xorg_multitouch_gestures) | `boolean` | Optional | cannot be null | [Archlinux provisioner variables](configuration-properties-the-enable_xorg_multitouch_gestures-schema.md "#/properties/enable_xorg_multitouch_gestures#/properties/enable_xorg_multitouch_gestures") |
| [debug](#debug)                                                     | `boolean` | Optional | cannot be null | [Archlinux provisioner variables](configuration-properties-the-debug-schema.md "#/properties/debug#/properties/debug")                                                                               |
| Additional Properties                                               | Any       | Optional | can be null    |                                                                                                                                                                                                      |

## hostname

System hostname (/etc/hostname).

`hostname`

*   is required

*   Type: `string` ([The hostname of this installation.](configuration-properties-the-hostname-of-this-installation.md))

*   cannot be null

*   defined in: [Archlinux provisioner variables](configuration-properties-the-hostname-of-this-installation.md "#/properties/hostname#/properties/hostname")

### hostname Type

`string` ([The hostname of this installation.](configuration-properties-the-hostname-of-this-installation.md))

### hostname Examples

```yaml
test

```

## username

The username of the first user to provision, that will be the sudoer.

`username`

*   is required

*   Type: `string` ([The username to create at the installation.](configuration-properties-the-username-to-create-at-the-installation.md))

*   cannot be null

*   defined in: [Archlinux provisioner variables](configuration-properties-the-username-to-create-at-the-installation.md "#/properties/username#/properties/username")

### username Type

`string` ([The username to create at the installation.](configuration-properties-the-username-to-create-at-the-installation.md))

### username Examples

```yaml
test

```

## kernel

The kernel to install from the Archlinux supported ones.

`kernel`

*   is required

*   Type: `string` ([The kernel schema](configuration-properties-the-kernel-schema.md))

*   cannot be null

*   defined in: [Archlinux provisioner variables](configuration-properties-the-kernel-schema.md "#/properties/kernel#/properties/kernel")

### kernel Type

`string` ([The kernel schema](configuration-properties-the-kernel-schema.md))

### kernel Constraints

**enum**: the value of this property must be equal to one of the following values:

| Value        | Explanation |
| :----------- | :---------- |
| `"standard"` |             |
| `"lts"`      |             |
| `"zen"`      |             |

### kernel Examples

```yaml
standard

```

## encryption

Activating this option configures the system to support file-system encryption

`encryption`

*   is optional

*   Type: `boolean` ([Encrypt the system](configuration-properties-encrypt-the-system.md))

*   cannot be null

*   defined in: [Archlinux provisioner variables](configuration-properties-encrypt-the-system.md "#/properties/encryption#/properties/encryption")

### encryption Type

`boolean` ([Encrypt the system](configuration-properties-encrypt-the-system.md))

### encryption Examples

```yaml
false

```

## enable_xorg_multitouch_gestures

Enable touchegg to have multitouch gestures under X11.

`enable_xorg_multitouch_gestures`

*   is optional

*   Type: `boolean` ([The enable_xorg_multitouch_gestures schema](configuration-properties-the-enable_xorg_multitouch_gestures-schema.md))

*   cannot be null

*   defined in: [Archlinux provisioner variables](configuration-properties-the-enable_xorg_multitouch_gestures-schema.md "#/properties/enable_xorg_multitouch_gestures#/properties/enable_xorg_multitouch_gestures")

### enable_xorg_multitouch_gestures Type

`boolean` ([The enable_xorg_multitouch_gestures schema](configuration-properties-the-enable_xorg_multitouch_gestures-schema.md))

### enable_xorg_multitouch_gestures Examples

```yaml
false

```

## debug

Enable debug to print verbose messages from supported roles.

`debug`

*   is optional

*   Type: `boolean` ([The debug schema](configuration-properties-the-debug-schema.md))

*   cannot be null

*   defined in: [Archlinux provisioner variables](configuration-properties-the-debug-schema.md "#/properties/debug#/properties/debug")

### debug Type

`boolean` ([The debug schema](configuration-properties-the-debug-schema.md))

### debug Examples

```yaml
false

```

## Additional Properties

Additional properties are allowed and do not have to follow a specific schema
