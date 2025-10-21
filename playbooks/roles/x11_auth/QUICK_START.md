# X11 Auth Role - Quick Start

## Immediate Fix (Manual)

If you're experiencing X11 authorization issues right now:

```bash
# Run from your graphical session user (NOT as aleph)
xhost +si:localuser:aleph
```

Then test as aleph:
```bash
sudo su - aleph
echo test | xclip -selection clipboard
xclip -o -selection clipboard
```

## Automatic Fix (via Playbook)

This role is automatically included in `after_format.yaml`. Just run:

```bash
make run_local
```

## What Gets Fixed

1. ✅ X server access for `aleph` user
2. ✅ Clipboard operations (xclip/wl-clipboard)
3. ✅ Vim clipboard integration (`set clipboard=unnamedplus`)
4. ✅ GUI apps launching from secondary user
5. ✅ Persistent configuration on reboot

## Verification

After running the playbook:

```bash
# 1. Switch to aleph
sudo su - aleph

# 2. Check DISPLAY
echo $DISPLAY  # Should show :0 or :1

# 3. Test xclip
echo test | xclip -selection clipboard
xclip -o -selection clipboard

# 4. Test Vim
vim
# Visual select text and press 'y'
# It should copy to system clipboard
```

## Still Not Working?

See the full documentation: [README.md](README.md)

Or the complete fix guide: [ISSUE_3_X11_CLIPBOARD_FIX.md](../../ISSUE_3_X11_CLIPBOARD_FIX.md)

