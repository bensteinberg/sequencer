// load class files
Machine.add(me.dir() + "/monome-classes/MonomeDevice.ck");
Machine.add(me.dir() + "/monome-classes/MonomeGrid.ck");

"/sequencer.ck" => string program;

// pass args to sequencer
for (0 => int i ; i < me.args() ; i++) {
  ":" + me.arg(i) +=> program;
}

// run sequencer
Machine.add(me.dir() + program);
