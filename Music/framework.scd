(
// todo: make some ~opensemble methods private

// taken from: Faking Objected-Oriented Programing in Supercollider with Events
// http://www.tmroyal.com/supercollider-pseudoclasses-with-events.html


//-----------------------------------
// FRAMEWORK: INIT STAGE
//-----------------------------------
Server.default.boot;

~opensemble = {
	var window;
	var oscIndicator, onsetIndicator, continuantIndicator,terminationIndicator;

	//-----------------------------------
	// SOUND UNIT FASE
	//-----------------------------------
	var sound_unit_fase = (
		isOnset:	{
			|self|
			['departure','emergence','anacrusis','attack','upbeat','downbeat'].includes(self.function)
		},
		isContinuant:	{
			|self|
			['passage','transition','prolongation','maintenance','statement'].includes(self.function)
		},
		isTermination:	{
			|self|
			['arrival','disappearence','closure','release','resolution','plane'].includes(self.function)
		},
		// fills object with incoming OSC data
		fill:	{
			|self, data|
			self.function = data[0];
			self.duration = data[1];
			self.unidirectional_motion = data[2];
			self.reciprocal_motion = data[3];
			self.cyclic_motion = data[4];
			self.characteristic_motion = data[5];
			self.texture_motion_relationship = data[6];
			self.texture_motion_continuity = data[7];
			self.texture_motion_periodic = data[8];
			self.texture_motion_acceleration = data[9];
			self.spectrum_type = data[10];
			self.spectrum_occupation = data[11];
			self.spectrum_plenitude = data[12];
			self.spectrum_concentration = data[13];
			self.spectrum_interstices = data[14];
			self.spectrum_crossover = data[15];
			self.spectrum_density = data[16];
		}

	);

	(

	register:  {
		|self, key, keywords, func|
		var sof = ();
		sof.parent = sound_unit_fase;
		sof.playEvent = func;
		sof.register(key, keywords );
		//todo: validate words
		self.dict.add(key -> [keywords,sof]);
		format("Function % registered\n", key);

	},
	unregister:  {
		|self, key|
		//todo: validate words
		self.dict.removeAt(key);
		format("Function % unregistered\n", key);
	},
	pick:  {
		|self, event|
		var wordsCount,best, sof=nil;

		if(self.dict.isEmpty,{"No functions registered!".postln;},{
			// pick best matching descriptor
			// wich will be by now the one
			// that matches more descriptive words
			wordsCount = self.dict.collect({ | item, key |
				item[0].count({ arg word; event.includes(word) });
			});

			//cant find a better way...
			best = wordsCount.findKeyForValue(wordsCount.maxItem);
			if(wordsCount[best]>0,{sof = self.dict[best][1];});
			if(sof.isNil,{"No function matches ".post;event.postln;});
		});

		sof; //can return nil
	},
	playEvent:  {
		|self, event|
		var sof = self.pick(event);
		if(sof.notNil,{
			// fill raw osc data
			sof.fill(event);
			// now play the event
			sof.playEvent;
		});
	},

	// test for Serendipity
	playRandomEvent:  {
		|self, event|
		var sof = self.dict.choose[1];
		if(sof.notNil,{
			// fill raw osc data
			sof.fill(event);
			// now play the event
			sof.playEvent;
		});
	},
	init:{
		|self|
		self.dict = Dictionary.new;
		self; // needed for method chaining
	}

).init; // call init upon creation
}.value;

"~opensemble is now defined.".underlined.postln;
"Loading contributions.".underlined.postln;
(thisProcess.nowExecutingPath.dirname +/+ "/contributions/*.scd").loadPaths(warn:false);


)


Task
