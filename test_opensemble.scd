

~msg = [5,\attack,3,\descent,\parabola,\rotation,\throw,\streaming,0,1,1,\saturated,\centre,1,1,1,1,\filled ]

~fill = ~msg[1..17]

~opensemble.playRandomEvent(~fill)





~test = Task({
	~playfill.value(); // WARNING: el fill debe ir al bus de salida comprimido

}).play;

~test.stop



s.quit

(
SystemClock.sched(0.1, ~playfill);
//~playfill.value(); // WARNING: el fill debe ir al bus de salida comprimido
"aca".postln;
)