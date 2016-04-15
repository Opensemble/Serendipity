//-----------------------------------------------------------------
// EJEMPLO
// Descripción:
//     Colaborador mz
//     Contribución: Espectro Armónico/Inarmónico, implementa distintos Onsets
//-----------------------------------------------------------------

// SynthDefs

// \samplePlayer
(
// buffer player with done action and control of envelope and panning
SynthDef(\dj_fx, {| out = 0, bufnum = 0 |
    Out.ar(out,
        PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum), doneAction:2)
    )
}).add;



//----------------------------------------------------
// initializaition function?
// could return an error code for succeess or failure

//~samplePlayer_init = {

	// Buffer Allocation
	//~pathLittle1 = "C:/Users/matias/Desktop/backup compu mechi/radiohead sound objects/Little1.wav";
	//~bufferLittle1 = Buffer.read(s, ~pathLittle1);


~dj_path = (thisProcess.nowExecutingPath.dirname.standardizePath ++ "/" ++ "dj_fx/Dj Puzzle Promo/").standardizePath;

~buf_dj = Buffer.read(s, ~dj_path ++ "Dj_Puzzle_Scratch_01"); // remember to free the buffer later.


	// Pdef definitionn

//};
//----------------------------------------------------,

~dj_fx_play = {

	Synth(\dj_fx, [\out, 0, \bufnum, ~buf_dj.bufnum]);
};

~dj_keywords = [\granular, \root, \centre, \parabola, \attack, \upbeat,\downbeat];

~opensemble.register(\dj_fx, ~dj_keywords, ~dj_fx_play);

)
