# Praat script "Dichotic speech noise combination"

# This Praat script takes a directory of sound files and a directory of noise files, combines the stimuli with the noise at a specified SNR but in two different channels, and writes the resultant stereo sounds as .wav files in a specified directory.
# Note that in this script the number of sound files should be no more than the number of noise files. Otherwise, the noise files will be combined with multiple sound files in the list.
# adapted from Daniel McCloy https://github.com/drammock/praat-semiauto/blob/master/MixSpeechNoise.praat
# Author: Chengjia Jason Ye
# Time: November 2025
# License: licensed under the GNU General Public License v3.0: http://www.gnu.org/licenses/gpl.html


form Mix speech with noise
  	comment Make sure to put trailing slashes in the folder paths.
	comment
	sentence stimuli_folder ./Stimuli/Audio_original/
	sentence noise_folder ./Stimuli/Babble_noise_16_talkers/
	sentence output_folder ./Stimuli/Audio_with_noise/
	real desired_SNR 0
	optionmenu finalIntensity: 3
		option match final intensity to stimulus intensity
		option maximize (scale peaks to plus/minus 1)
		option just add noise to signal (don't scale result)
	
endform

# Display a confirmation of the desired SNR level
echo Mixing at SNR 'desired_SNR' 


# Create the output folder
createFolder(output_folder$)
# if output_folder already exists, this does nothing

# Stimuli
stimList = Create Strings as file list... stimList 'stimuli_folder$'*.wav
nStim = Get number of strings

# Noise
noiseList = Create Strings as file list... noiseList 'noise_folder$'*.wav
nNoise = Get number of strings

if nStim > nNoise
	appendInfoLine "There are more stimuli than noise files. Noise files will thus be used more than once."
endif

# Read each stimulus and noise

for i from 1 to nStim
	select stimList
	soundname$ = Get string... i
	# Open a sound file from the listing:
	sound = Read from file... 'stimuli_folder$''soundname$'
	soundMono = Convert to mono
	select sound
	Remove
	sound = soundMono

	select sound
	soundDur = Get total duration
	soundRMS = Get root-mean-square... 0 0
	soundInt = Get intensity (dB)

	select noiseList
	
	# If-condition for the case when there are more stimuli than noise files
	if nStim <= nNoise
		noisename$ = Get string... i
	else
		j = i - nNoise * floor((i - 1) / nNoise)
        	noisename$ = Get string... j
	endif

	# Open a noise file from the listing:
	noise = Read from file... 'noise_folder$''noisename$'
	noiseDur = Get total duration

	while soundDur > noiseDur
		# duplicate noise and concatenate it to itself
		select noise
		temp = Concatenate
		plus noise
		noise = Concatenate
		select temp
		Remove
		select noise
		noiseDur = Get total duration
  	endwhile

	if noiseDur > soundDur
		# trim the noise to the same length as the sound
		noiseTrimmed = Extract part... 0 soundDur "rectangular" 1.0 "yes"
	endif
	
	select noise
	Remove
	noise = noiseTrimmed
	select noise
		Fade in... 0 0 0.4 yes
		Fade out... 0 soundDur-0.4 0.4 yes
	noiseRMS = Get root-mean-square... 0 0
	noiseInt = Get intensity (dB)
	

	# Calculate the noise coefficient that yields desired SNR
	# SNR = 20*log10(SignalAmpl/NoiseAmpl)
	# NoiseAmpl = SignalAmpl / (10^(SNR/20))
	noiseAdjustCoef = (soundRMS / (10^(desired_SNR/20))) / noiseRMS
	appendInfoLine: "coef of ", soundname$, " combined with noise ", noisename$, " at SNR = ", desired_SNR, " is :", noiseAdjustCoef 

	# Combine signal and noise at the given SNR
	select noise
	Formula...  noiseAdjustCoef * self
	plusObject: sound
	stereo = Combine to stereo
	

	# Scale the result when necessary
  	if finalIntensity = 1
		# scale to match original
		Scale intensity... soundInt

	elsif finalIntensity = 2
		# scale to +/- 1
		Scale peak... 0.99
  	endif

	# Write the output
	select stereo
	Save as WAV file... 'output_folder$''desired_SNR'_SNR_'soundname$'

	# Remove files from the list
	Remove
	select sound
	plus noise
	Remove

endfor


if finalIntensity = 1
	printline Scaling to match original intensities.
elsif finalIntensity = 2
	printline Scaling peaks to +/- 0.99.
else
	printline No scaling requested, watch out for clipping.
endif

select stimList
plus noiseList
Remove
printline Done!
	
	