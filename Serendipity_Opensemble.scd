// convert mp3 to wav
// for f in tracks2/*.mp3;do lame --decode $f ${f%.mp3}.wav;done;
// move wav files to proper folder
// mv tracks2/*.wav wavs

s.quit

(
s = Server.local;
s.boot;
)

(
		// now play it

SynthDef(\playBuf,{ arg out = 0, bufnum, startpos;
	Out.ar( out,
	PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum),startPos:startpos)
)
}).add;

~mainBus = Bus.audio(s, 2);

SynthDef(\Compre, {arg out = 0, in, gate=1;
	var sig, env;
	sig = In.ar(in, 2);
	// main effects here

	// compressor
	sig = Compander.ar(sig, sig,
        thresh: 0.9,
        slopeBelow: 1,
        slopeAbove: 0.5,
        clampTime: 0.01,
        relaxTime: 0.01
    );

	Compander.ar(sig, sig,
        thresh: 0.9,
        slopeBelow: 1,
        slopeAbove: 0.1,
        clampTime: 0.01,
        relaxTime: 0.01
    );

	env = EnvGen.ar(Env.asr(0.1,1,10),gate,doneAction:2);

	// ---
	Out.ar(out, sig*env);
}).add;

//s.sync;
~mainCompre = Synth(\Compre, [\out, 0,\in, ~mainBus]);

// path to tracks
~wavsDir = thisProcess.nowExecutingPath.dirname ++ "/wavs/".standardizePath;


// features
~featuresDir = thisProcess.nowExecutingPath.dirname ++ "/features/".standardizePath;
)



(
l = (0..100).collect{ arg item,i;
	var tfd,bsfd,bffd,gfd,genre,bs, bf;
	var track = "track"++ i.asStringToBase(10, 3);
	var basename = ~featuresDir ++ track;
	var wavfile = ~wavsDir ++ track++".wav";

	tfd = File(basename ++ ".tempo","r");
	bsfd = File(basename ++ ".beat_secs","r");
	bffd = File(basename ++ ".beat_frames","r");
	gfd = File(basename ++ ".genre","r");

	t = tfd.readAllString.asFloat;
	bs = bsfd.readAllString.split($\n).asFloat;
	bf = bffd.readAllString.split($\n).asInt;
	genre = gfd.readAllString.replace("\n","");

	tfd.close;
	bsfd.close;
	bffd.close;


	d = Dictionary.new;
	d.add(\tempo -> t);
	d.add(\wavfile -> wavfile);
	d.add(\genre -> genre);
	d.add(\beats_skip -> (16 * [1,2].choose));
	d.add(\beats_last -> (16 * [1,2].choose));
	d.add(\beat_secs -> bs);
	d.add(\beat_frames -> bf);
	d.add(\index -> i);

	d;
};

)



(

g = Set.new;

l.do({arg item, i;
	var genre =  item.at(\genre);
	if(genre.isEmpty || g.includes(genre) ,
		{},
		{ g.add(genre)});
});


h = "Electronic"; //g.choose;

l.count({arg item, i;
	item.at(\genre) == h;
});

o = l.select({arg item, i;
	item.at(\genre) == h;
});
o.sortBy(\tempo);

)


(
Buffer.freeAll;
// read a soundfile
b = o.collect{ arg item,i;
	Buffer.read(s, item.at(\wavfile));
};


)

(
//inicializar opensemble..
//elegir distintos gestos

//función con fills de transición
~playfill = {
~msg = [5,\attack,3,\descent,\parabola,\rotation,\throw,\streaming,0,1,1,\saturated,\centre,1,1,1,1,\filled ];
~fill = ~msg[1..17];
~opensemble.playRandomEvent(~fill);

};
)

//esperar unos segundos antes de disparar esto
(

//SystemClock.sched(30, { ~mainCompre.release(); ~mainRoutine.stop; "release".postln});


{
	//start 15min set. Sched release stage (14x60+50segs from now). Release 10 sec. WE NEED TO END OPENSEMBLE

	//start music
	o.do({ arg item, i;

	//var duration = item.at(\beat_secs)[item.at(\beats_skip)+item.at(\beats_last)] - item.at(\beat_secs)[item.at(\beats_skip)];

	var duration = item.at(\beats_last); // el cálculo anterior tira errores

	x = Synth(\playBuf,[
		\out, ~mainBus,
		\bufnum, b[i].bufnum,
		\startpos, item.at(\beat_frames)[item.at(\beats_skip)]
	]);
	duration.wait;
	x.free;
	s.sync;
	"play fill".postln;
	SystemClock.sched(0.1, ~playfill);  // WARNING: el fill debe ir al bus de salida comprimido

})}.fork;

//"DONE".postln;
)


CmdPeriod.run


