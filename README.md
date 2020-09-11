# TimeShifter

Edit BPM points and keep the notes snapped.

# Installation

Download and copy to Quaver/Plugins.

The path will look like : `Quaver\Plugins\TimeShifter\plugin.lua`

`plugin.lua` and `settings.ini` are required.

# Usage

The plugin will list every Timing Point in the current map.

You can edit their offset and BPM, then Apply. Changes can be reverted with Ctrl+Z.

Caution : Avoid editing multiple BPM points at once. They are processed one after the other as if they were different batches. If notes were to be put on another BPM section due to lowering the BPM or changing the offset too much, it would count as if it was part of it when this next section is processed.

It is advised to do backups of your maps when using this tool.