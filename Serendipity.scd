(
{
var baseDir= thisProcess.nowExecutingPath.dirname.standardizePath;
var lamePath= baseDir ++ "/bin/lame.exe".standardizePath;
var featuresPath= baseDir ++ "/features/".standardizePath;
var wavsPath= baseDir ++ "/wavs/".standardizePath;

s = Server.local;
s.boot;
Buffer.freeAll;

//avoid loading features if they are still loaded from previous execution
if(l.notNil,"Features are still in RAM, dont load from disk right now.".warn,{

		"Begin gathering track features.".underlined.postln;


		l = PathName(baseDir++"/tracks/").files.collect({arg file, i;
			var tfd,bsfd,bffd,gfd,rfd,t,genre,bs, bf,r;
			var track = file.fileNameWithoutExtension;
			var basename = featuresPath ++ track;

			tfd = File(basename ++ ".tempo","r");
			bsfd = File(basename ++ ".beat_secs","r");
			bffd = File(basename ++ ".beat_frames","r");
			gfd = File(basename ++ ".genre","r");
			rfd = File(basename ++ ".rmse","r");

			format("--> Attempting to gather % features...",track).post;


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

			d.add(\beat_start -> (16 * [1,2,4,8].choose));
			d.add(\beats_length -> (4 * [1,2].choose));
			d.add(\loop_times -> 4);

			"ok.".postln;
			//return dictionary
			d;


		});
		"Done with features query.".underlined.postln;

});

//reject tracks without genre
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
t = (o.collect({arg item, i;
	item.at(\tempo);
}).sum/o.size).round(10);

format("\nSelected genre: %\nAverage tempo : %\nTracks matched: %\n\n",h,t, o.size).postln;

"Convert to wav all selected mp3 files".underlined.postln;

o.do{ arg item,i;
	var input= item.at(\originalFile).fullPath.standardizePath;
	var output = wavsPath++item.at(\originalFile).fileNameWithoutExtension ++".wav";
		if(File.exists(output),{
			format("--> File % already in WAV format.",item.at(\originalFile).fileName).postln;
		},{
			var cmd = format("% --decode --silent \"%\"  \"%\"", lamePath, input, output);
			format("--> Converting % to %",item.at(\originalFile).fileName, output).postln;
			//using this instead because it is blocking
			cmd.unixCmdGetStdOut;
		});

	//adds wav file path to dictionary
	item.add(\wavfile->output);
	//adds a playback rate
	item.add(\playback_rate-> (t/item.at(\tempo)) );


};

"All files converted".underlined.postln;






"Creating main out bus".postln;

~mainBus = Bus.audio(s, 2);

"Defining play buf synth def".postln;

SynthDef(\playBuf,{ arg out = 0, bufnum,rate=1, trigger=1,startpos=0,loop=0;
	Out.ar( out,
		PlayBuf.ar(2, bufnum, rate,trigger,startpos,loop,2)
	)
}).add;

"Defining compresor synth def".postln;

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

"Waiting server to be on sync".postln;
{s.sync};
"Declaring main compresor on main bus".postln;
~mainCompre = Synth(\Compre, [\out, 0,\in, ~mainBus]);


//esperar unos segundos antes de disparar esto
1.wait;
//SystemClock.sched(30, { ~mainCompre.release(); ~mainRoutine.stop; "release".postln});


"Loading buffers".underlined.postln;


// read a soundfile
b = o.collect{ arg item,i;
	var bb;
	var startFrame, endFrame, numFrames;
	startFrame = item.at(\beat_frames)[item.at(\beat_start)]*1024-1023;
	endFrame = item.at(\beat_frames)[item.at(\beat_start)+item.at(\beats_length)]*1024-1023;
	numFrames = endFrame - startFrame - 1;
	bb = Buffer.read(s, item.at(\wavfile), startFrame, numFrames);
	{s.sync;}.fork; //should wait?
	bb;
};

"Buffers loaded".underlined.postln;



}.fork;



)


s.scope
(
		x = Synth(\playBuf,[
			\out, ~mainBus,
			\bufnum, b[1].bufnum,
	        \rate, o[1].at(\playback_rate),
	        \loop,1
		]);

		y = Synth(\playBuf,[
			\out, ~mainBus,
			\bufnum, b[2].bufnum,
	        \rate, o[2].at(\playback_rate),
	        \loop,1
		]);

)

x.set(\trigger,1);
x.set(\trigger,-1);
x.free;
y.free;

(

{
	o.do({ arg item, i;

		x = Synth(\playBuf,[
			\out, ~mainBus,
			\bufnum, b[i].bufnum
		]);


		1.wait;
		x.free;
		s.sync; //evita referencias perdidas


	});
}.fork;

)


(
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

