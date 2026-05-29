form Get duration, midpoint formant, first two harmonics and pitch contour
	comment Directory of sound files. Include the final "/".
	text sound_directory ./results/1/
	sentence Sound_file_extension .wav
	comment Path of the resulting text file for duration, formants and harmonics:
	text resultsfile ./data/resultsfile_1.txt
	comment Path of the resulting text file for duration and pitch:
	text pitchfile ./data/pitchfile_1.txt

	comment Formant analysis parameters
	positive Time_step 0.005
	integer Maximum_number_of_formants 5
	positive Maximum_formant_(Hz) 5500
	positive Window_length_(s) 0.025
	real Preemphasis_from_(Hz) 50
endform

# Make a listing of all the sound files in a directory:
Create Strings as file list... list 'sound_directory$'*'sound_file_extension$'
numberOfFiles = Get number of strings

# Check if the result files exists:
if fileReadable (resultsfile$)
	pause The file 'resultsfile$' already exists! Do you want to overwrite it?
	filedelete 'resultsfile$'
endif

if fileReadable (pitchfile$)
	pause The file 'pitchfile$' already exists! Do you want to overwrite it?
	filedelete 'pitchfile$'
endif

# Create a header row for the result files:
header$ = "Filename	Duration	F1_midpoint	F2_midpoint	H1	H2	H1-H2_diff	f0_40ms	f0_80ms'newline$'"
fileappend "'resultsfile$'" 'header$'
header_pitch$ = "Filename	Duration	timepoint	pitch'newline$'"
fileappend "'pitchfile$'" 'header_pitch$'

# Open each sound file in the directory:
for ifile from 1 to numberOfFiles
	select Strings list
	filename$ = Get string... ifile
	Read from file... 'sound_directory$''filename$'

	# get the name of the sound object:
	soundname$ = selected$ ("Sound", 1)
	
	# get the duration of the sound object:
	select Sound 'soundname$'
	duration_s = Get total duration
	duration = round(duration_s * 1000)
	midpoint = duration_s * 0.5

	# get the formant information of the sound object:
	select Sound 'soundname$'
	To Formant (burg)... time_step maximum_number_of_formants maximum_formant window_length preemphasis_from
	select Formant 'soundname$'

	f1_50 = Get value at time... 1 midpoint Hertz Linear
	f1_50 = round(f1_50)
	f2_50 = Get value at time... 2 midpoint Hertz Linear
	f2_50 = round(f2_50)
	select Formant 'soundname$'
	Remove

	# get the pointprocess
	select Sound 'soundname$'
	pitch = To Pitch (filtered autocorrelation): 0.0, 50, 800, 15, "no", 0.03, 0.09, 0.50, 0.055, 0.35, 0.14

	if duration_s >= 0.2
		time_step_pitch = 0.02
	else
		time_step_pitch = 0.01
	endif

	number_of_steps = floor(duration_s / time_step_pitch)
	

	for istep from 0 to number_of_steps
		current_time = istep * time_step_pitch
		f0 = Get value at time: current_time, "Hertz", "Linear"
		# Replace undefined values with NA
		if f0 = undefined
			value$ = "NA"
		else
			value$ = string$(round(f0))
			# Save result to text file:
			pitchline$ = "'soundname$'	'duration'	'current_time'	'value$''newline$'"
			fileappend "'pitchfile$'" 'pitchline$'
		endif
		if current_time == 0.04
			f0_40ms = round(f0*100)/100
		elsif current_time == 0.08
			f0_80ms = round(f0*100)/100
		endif
		endfor

	select Sound 'soundname$'
	plusObject: pitch
	pointprocess = To PointProcess (cc)
	removeObject: pitch

	# get the beginning and end point of the given number of the period
	selectObject: pointprocess
	starting_time = Get time from index: 1
	ending_time = starting_time
	for interval from 1 to 3
 		interval_time = Get interval: (ending_time + 0.0001)
		ending_time = ending_time + interval_time
	endfor

	select Sound 'soundname$'
	Extract part: starting_time, ending_time, "rectangular", 1.0, "yes"
	To Spectrum: "no"

	# remove the pointprocess file
	
	selectObject: pointprocess
	Remove
	
	# get the H1 and H2 difference
	partname$ = soundname$ + "_part"
	select Spectrum 'partname$'
	table = Tabulate: 1, 1, 0, 0, 0, 1
	tablename$ = "Table " + partname$
	b3 = object [tablename$, 3, 3]
	b4 = object [tablename$, 4, 3]
	b5 = object [tablename$, 5, 3]
	b6 = object [tablename$, 6, 3]
	b7 = object [tablename$, 7, 3]
	b8 = object [tablename$, 8, 3]
	if b4 > b3 and b4 > b5
		h1 = round(b4*100)/100
	else
		h1 = -1
	endif

	if b7 > b6 and b7 > b8
		h2 = round(b7*100)/100
	else
		h2 = -1
	endif

	h1_h2 = round((h1 - h2)*100)/100
	selectObject: table
	Remove

	if h1 != -1 and h2 != -1
		select Spectrum 'partname$'
		Remove
		select Sound 'partname$'
		Remove
	endif

	# Save result to text file:
	resultline$ = "'soundname$'	'duration'	'f1_50'	'f2_50'	'h1'	'h2'	'h1_h2'	'f0_40ms'	'f0_80ms''newline$'"
	fileappend "'resultsfile$'" 'resultline$'

endfor

