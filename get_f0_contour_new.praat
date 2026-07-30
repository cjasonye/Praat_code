form Get pitch contour
	comment Directory of sound files. Include the final "/".
	text sound_directory ./results/1/
	sentence Sound_file_extension .wav
	comment Path of the resulting text file for duration and pitch:
	text pitchfile ./data/pitchfile_1.txt
	comment Time step for extracting the f0 (default is 0.01 s)
	real time_step_pitch 0.01
	comment floor pitch search floor
	real floor 70
	comment ceiling pitch search top
	real ceiling 300
endform

# Make a listing of all the sound files in a directory:
Create Strings as file list... list 'sound_directory$'*'sound_file_extension$'
numberOfFiles = Get number of strings

# Check if the result files exists:
if fileReadable (pitchfile$)
	pause The file 'pitchfile$' already exists! Do you want to overwrite it?
	filedelete 'pitchfile$'
endif

# Create a header row for the result files:
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

	# get the pointprocess
	select Sound 'soundname$'
	pitch = To Pitch (filtered autocorrelation): 0.0, floor, ceiling, 15, "no", 0.03, 0.09, 0.50, 0.055, 0.35, 0.14

	number_of_steps = floor(duration_s / time_step_pitch)
	

	for istep from 0 to number_of_steps
		current_time = round(istep * time_step_pitch * 100)/100
		f0 = Get value at time: current_time, "Hertz", "Linear"
		if f0 != undefined
			value = round(f0*10)/10
			# Save result to text file:
			pitchline$ = "'soundname$'	'duration'	'current_time'	'value''newline$'"
			fileappend "'pitchfile$'" 'pitchline$'
		endif
	endfor

	removeObject: pitch

endfor

