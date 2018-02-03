//// SETUP
//
// set the output and base note
"ding" => string output;
60     => int base;
if (me.arg(0) != "") {
  me.arg(0) => output;
}
if (me.arg(1) != "") {
  me.arg(1) => Std.atoi => base;
}

// setup for when the output is via samples ":ding"
SndBuf bufs[6];

for (0 => int i ; i < 6 ; i++) {
  // pass filename base in args?
  me.sourceDir() + "/audio/ding" + (i + 1) + ".wav" => bufs[i].read;
  // suppress first playthrough
  bufs[i].samples() - 1 => bufs[i].pos;
  bufs[i] => dac;
}

// setup for when the output is via dadamachine ":dada"
MidiOut mout;
mout.open(1);

// set up the grid
MonomeDevice m;
MonomeGrid grid;

m.getDeviceInfo() @=> string devices[][];

for (0 => int i ; i < devices.cap() ; i++) {
  <<< devices[i][0], devices[i][1], devices[i][2] >>>;
  <<< "connecting to", "grid" >>>;
  "128h" => grid.gridSize;         // change to match your device
  devices[i][2] => Std.atoi => grid.connect;
}

// set up the sequencer, starting with one empty page
// full mask, 16 hits, would be 65535
int sequencer[][];
[[0, 0, 0, 0, 0, 0]] @=> sequencer;

// set up the tempo
// consider changing this to something bpm-derived
0.2::second => dur interval;

// setup for reporting when a page change occurs
class PageEvent extends Event
{
  int page;
}
PageEvent p;
0 => int currentPage;

// set up initial conditions
grid.ledAllOff();
// start unmuted and show it
0 => int mute;
grid.ledOn(0, 7);
// use full loop
0 => int loopStart;
15 => int loopEnd;
grid.rowOn(6);
// and show the current page 
showCurrentPage();


//// MAIN ACTION
//
// listen for button presses
spork ~ buttonResponder(grid.button);

// watch for page changes
spork ~ pageWatcher(p);

// run all six rows
for (0 => int i; i < 6 ; i++) {
  spork ~ march(i);
}

// and wait forever
while (true) {
  10 :: second => now;
}


//// FUNCTIONS
//
// watch for and mark page changes
fun void pageWatcher(PageEvent event)
{
  while (true) {
    event => now;
    event.page => currentPage;
    showCurrentPage();
  }
}

// march down a row
fun void march(int row)
{
  [0, 0] @=> int map[];
  while (true) {
    for (loopStart => int i ; i < loopEnd + 1 ; i++ ) {
      if (sequencer[currentPage][row] & Math.pow(2, i) $ int) {
         spork ~ play(row);
      }
      grid.rowSet(0, row, remap(row, i));
      interval => now;
    }
    // only signal page change from the first marcher
    if (row == 0) {
      (currentPage + 1) % sequencer.cap() => p.page;
      p.signal();
    }
  }
}

// play a sample or strike a dadanote
fun void play(int row)
{
  if (mute == 0) {
    if (output == "ding") {
      0 => bufs[row].pos;
      1.0::second => now;
    } else {
      if (output == "dada") {
        MidiMsg msg;
        row + base => int note;

        0x90 => msg.data1;
        note => msg.data2;
        127 => msg.data3;
        mout.send(msg);
  
        0.05::second => now;
  
        0x80 => msg.data1;
        note => msg.data2;
        0 => msg.data3;
        mout.send(msg);
  
        interval - 0.05::second => now;
      }
    }
  }
}

// convert the int aka bitmap for a row into the pair of ints needed by rowSet
fun int[] remap(int row, int position)
{
  sequencer[currentPage][row] | Math.pow(2, position) $ int => int raw;
  return [raw & 255, raw >> 8];
}

// display current page in binary at right end of bottom row
fun void showCurrentPage()
{
  currentPage + 1 => int page;
  for (0 => int i ; i < 8 ; i++) {
    grid.ledOff(15 - i, 7);
    if (page & Math.pow(2, i) $ int) {
      grid.ledOn(15 - i, 7);
    }
  }
}

// watch for button presses
fun void buttonResponder(Event e)
{
  while (true) {
    e => now;
    if (grid.y < sequencer[0].cap()) {
			//// these are presses in the sequencer proper
      // we don't care about keyup
      if (grid.state == 1) {
        Math.pow(2, grid.x) $ int => int mask;
        if (sequencer[currentPage][grid.y] & mask) {
          grid.ledOff(grid.x, grid.y);
          sequencer[currentPage][grid.y] ^ mask => sequencer[currentPage][grid.y];
        } else {
          grid.ledOn(grid.x, grid.y);
          sequencer[currentPage][grid.y] | mask => sequencer[currentPage][grid.y];
        }
      }
    } else {
      if (grid.y == 6) {
        //// loop interface presses
        if (grid.x < loopStart) {
          grid.x => loopStart;
        } else {
          if (grid.x > loopEnd) {
            grid.x => loopEnd;
          } else {
            if (grid.x - loopStart <= loopEnd - grid.x) {
              grid.x => loopStart;
            } else {
              grid.x => loopEnd;
            }
          }
        }
        // display new loop range
        for (0 => int i; i < 16 ; i++) {
          grid.ledOff(i, 6);
          if (i >= loopStart && i <= loopEnd) {
            grid.ledOn(i, 6);
          }
        }
      } else {
        //// control interface presses on bottom row
        // more ideas:
        // - how to implement pause?
        // - new random page
        // - random march?
        if (grid.x == 0) {
				  // unmute
          // we don't care about keyup
          if (grid.state == 1) {
            0 => mute;
            grid.ledOn(0, 7);
            grid.ledOff(1, 7);
          }
        }
        if (grid.x == 1) {
				  // mute
          // we don't care about keyup
          if (grid.state == 1) {
            1 => mute;
            grid.ledOn(1, 7);
            grid.ledOff(0, 7);
          }
        }
        if (grid.x == 2) {
				  // slow down
          if (grid.state == 1) {
            grid.ledOn(2, 7);
            interval + 0.01::second => interval;
          } else {
            grid.ledOff(2, 7);
          }
        }
        if (grid.x == 3) {
				  // speed up
          if (grid.state == 1) {
            grid.ledOn(3, 7);
            if (interval > 0.05::second) {
              interval - 0.01::second => interval;
            }
          } else {
            grid.ledOff(3, 7);
          }
        }
			  if (grid.x == 4) {
				  // new blank page
				  if (grid.state == 1) {
					  grid.ledOn(4, 7);
						sequencer << [0, 0, 0, 0, 0, 0];
				  } else {
					  grid.ledOff(4, 7);
				  }
			  }
			  if (grid.x == 5) {
				  // new page from current
				  if (grid.state == 1) {
					  grid.ledOn(5, 7);
						sequencer << [sequencer[currentPage][0],
						              sequencer[currentPage][1],
					                sequencer[currentPage][2],
						              sequencer[currentPage][3],
						              sequencer[currentPage][4],
						              sequencer[currentPage][5]];
				  } else {
					  grid.ledOff(5, 7);
				  }
			  }
			  if (grid.x == 6) {
				  // remove a page
				  if (grid.state == 1) {
					  grid.ledOn(6, 7);
						// remove last page WHEN NOT ON IT
						// i.e. never remove very last (aka first) page
						if (currentPage != sequencer.cap() - 1) {
							sequencer.popBack();
						}
				  } else {
					  grid.ledOff(6, 7);
				  }
			  }
		  }
    }
    1::ms => now;
  }
}
