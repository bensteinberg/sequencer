sequencer
=========

This sequencer, written in [ChucK](http://chuck.stanford.edu/), is
intended to drive [dadamachines](https://dadamachines.com/) via MIDI
or play samples, using a [monome](https://monome.org/)
[grid](https://monome.org/docs/grid/) as interface.

setup
-----

You should already have ChucK
[installed](http://chuck.stanford.edu/release/), your grid working
with [serialosc](https://monome.org/docs/setup/), and if you have one,
your dadamachine [set up](https://dadamachines.com/getstarted/).

Clone this repo, then initialize submodules to get the necessary
monome classes:

    git clone https://github.com/bensteinberg/sequencer.git
    git submodule init

Run the program without arguments, or with the `ding` argument, to
play samples:

    chuck init.ck
    chuck init.ck:ding
    
Run the program with the `dada` argument to send MIDI output:

    chuck init.ck:dada
    
This program assumes that the base note number your dadamachine has
learned is 60; if that's not the case, set it in an additional
argument like this:

    chuck init.ck:dada:72
    
interface
---------

At the moment, this program assumes the grid is a 128 and
horizontal. The top six rows are the sequencer proper -- each row has
sixteen steps and drives one output.

The next row controls loop start and end. The loop is initially the
full sixteen steps, but pressing buttons in this row adjusts the
endpoints. Loop start and end are the same for all pages -- see below.

The bottom row controls muting, speed, and paging:

- The first button from the left is the play indicator and control,
  and the second mutes playback. 
- The third button from the left slows the tempo, and the fourth
  speeds it up.
- The fifth button creates a new blank page, and the sixth button
  creates a new page from the current page.
- The seventh button removes the last page in the sequence.

The current page is displayed in binary at the right end of the bottom
row. Initially, there's only one page.
