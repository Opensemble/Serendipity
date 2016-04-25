(
{
var baseDir= thisProcess.nowExecutingPath.dirname.standardizePath;
var lamePath= baseDir ++ "/bin/lame.exe".standardizePath;
var featuresPath= baseDir ++ "/features/".standardizePath;
var wavsPath= baseDir ++ "/wavs/".standardizePath;


l = List.new;

PathName(baseDir++"/tracks/").files.do({arg file, i;
	var tfd,bsfd,bffd,gfd,rfd,t,genre,bs, bf,r;
	var track = file.fileNameWithoutExtension;
	var basename = featuresPath ++ track;

	tfd = File(basename ++ ".tempo","r");
	bsfd = File(basename ++ ".beat_secs","r");
	bffd = File(basename ++ ".beat_frames","r");
	gfd = File(basename ++ ".genre","r");
	rfd = File(basename ++ ".rmse","r");

	format("attempting to gather % features...",track).post;


	t = tfd.readAllString.asFloat;
	bs = bsfd.readAllString.split($\n).asFloat;
	bf = bffd.readAllString.split($\n).asInt;
	genre = gfd.readAllString.replace("\n","").replace("\r","");
	r = rfd.readAllString.split($\n).asFloat;

	tfd.close;
	bsfd.close;
	bffd.close;
	gfd.close;
	rfd.close;

	d = Dictionary.new;
	d.add(\tempo -> t);
	d.add(\originalFile -> file);
	d.add(\genre -> genre);
	d.add(\beat_secs -> bs);
	d.add(\beat_frames -> bf);
	d.add(\rmse -> r);

	// segment analisys function

		// si el RMS es mayor a tanto y múltiplo de 4, lo selecciono
		// y podemos usar segmentos sólo en un rango de RMS (para beats_skip)

		// armar una librería de segmentos por archivo:
		      // RMS, CROMA Y/O CENTROIDE ESPECTRAL, para empezar

		// luego vamos ordenando los segmentos por similitud
		// y repetimos hasta lograr 15 minutos


	// segment analisys function

	d.add(\beats_skip -> (16 * [1,2,4,8].choose));
	d.add(\beats_last -> (4 * [1,2].choose));
	d.add(\loop_times -> 4);

	"ok.".postln;
	l.add(d);


});

l = l.reject({arg item, i;
	item.at(\genre).size==0;
});

g = Set.new;

l.do({arg item, i;
	var genre =  item.at(\genre);
	if(g.includes(genre) ,
		{},
		{ g.add(genre)});
});

//selects a genre
h = g.choose;


//selects matching genre tracks
o = l.select({arg item, i;
	item.at(\genre) == h;
});

o.sortBy(\tempo);
format("Selected genre: % , % tracks matched.",h, o.size).postln;

//convert to wav all selected mp3 files
// for f in tracks2/*.mp3;do lame --decode $f ${f%.mp3}.wav;done;
// mv tracks2/*.wav wavs
b = o.collect{ arg item,i;
	var input= item.at(\originalFile).fullPath.standardizePath;
	var output = wavsPath++item.at(\originalFile).fileNameWithoutExtension ++".wav";
	var cmd = format("% --decode --silent \"%\"  \"%\"", lamePath, input, output);
	//cmd.unixCmd;
	format("converting % ",item.at(\originalFile).fileName).postln;


	cmd.unixCmdGetStdOut;


	//adds wav file path to dictionary
	item.add(\wavfile->output);
};

"all files converted".postln;

1.wait;
"loading buffers".postln;

Buffer.freeAll;
// read a soundfile

b = o.collect{ arg item,i; var bb;
	bb = Buffer.read(s, item.at(\wavfile));
	{s.sync;}.fork; //should wait?
	bb;

};
"buffers loaded".postln;


"creating main out bus".postln;

~mainBus = Bus.audio(s, 2);

"defining play buf synth def".postln;

SynthDef(\playBuf,{ arg out = 0, bufnum, startpos, loop_times;
	Out.ar( out,
	loop_times.do {
	PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum),startPos:startpos)
	}
)
}).add;

"defining compresor synth def".postln;

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

"waiting server to be on sync".postln;
{s.sync};
"declaring main compresor on main bus".postln;
~mainCompre = Synth(\Compre, [\out, 0,\in, ~mainBus]);


}.fork;
)





//esperar unos segundos antes de disparar esto
(
//SystemClock.sched(30, { ~mainCompre.release(); ~mainRoutine.stop; "release".postln});


{
	//start 15min set. Sched release stage (14x60+50segs from now). Release 10 sec. WE NEED TO END OPENSEMBLE

	//start music
	o.do({ arg item, i;
	var skip = item.at(\beats_skip);
	var last = item.at(\beats_last);
	var duration = (item.at(\beat_secs)[skip+last-1] - item.at(\beat_secs)[skip-1]);

	//repeat
	//item.at(\loop_times).postln;
	//duration = duration * item.at(\loop_times);

		//repeat, puede hacerse mejor
	item.at(\loop_times).do {

	x = Synth(\playBuf,[
		\out, ~mainBus,
		\bufnum, b[i].bufnum,
		\startpos, item.at(\beat_frames)[item.at(\beats_skip)]
	]);


	duration.wait;
	x.free;
	s.sync; //evita referencias perdidas
	};

	"play fill start".postln;
	//~playfill.value;  //esto es asincrónico

})}.fork;

)


CmdPeriod.run

