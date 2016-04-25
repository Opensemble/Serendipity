 # to download related features from server:
 for f in `ls ../tracks/`;do wget -N http://aum.dartmouth.edu/~mcasey/AlgoRhythms_Data/features/${f/mp3/tempo}; done;
 for f in `ls ../tracks/`;do wget -N http://aum.dartmouth.edu/~mcasey/AlgoRhythms_Data/features/${f/mp3/beat_secs}; done;
 for f in `ls ../tracks/`;do wget -N http://aum.dartmouth.edu/~mcasey/AlgoRhythms_Data/features/${f/mp3/beat_frames}; done;
 for f in `ls ../tracks/`;do wget -N http://aum.dartmouth.edu/~mcasey/AlgoRhythms_Data/features/${f/mp3/genre}; done;
 for f in `ls ../tracks/`;do wget -N http://aum.dartmouth.edu/~mcasey/AlgoRhythms_Data/features/${f/mp3/rmse}; done;