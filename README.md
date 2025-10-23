# fpop

A tool that uses FZF to present useful developer experiences.

## Dependencies

You must have the CLI utility `fzf` installed, it is available through your
package manager.

## Popular Commands

### `:OldFiles`

Shows old files that you have had open recently. This is similar to `:browse
oldfiles`

### `:Buffers`

Lets you select a new active buffer from the open buffers. This would be similar
to `:ls` followed by `:b<buffer_number>`.

## Library Utilities

You can use the `fpop#Picker` method to create your own FZF Popup selections.
This method is documented within the help pages, but ultimately you need to
provide a list of selections to this method as well as a dictionary that
includes at least a callback function that you can use to process the selection.
A few default selection mechanisms exist within `fpop` for you already that know
how to select output.

--------------------------------------------------------------------------------

See more help with `:help fpop`
