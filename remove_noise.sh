# 1. extract audio from all videos (assuming .mp4 videos).
for FILE in *.mp4; do ffmpeg -i $FILE ${FILE%%.mp4}.wav; done

# 2. use the first second of the first audio file as the noise sample.
sox `ls *.wav | head -1` -n trim 0 1 noiseprof noise.prof

# Replace with a specific noise sample file if the first second doesn't work for you:
# sox noise.wav -n noiseprof noise.prof

# 3. clean the audio with noise reduction and normalise filters.
for FILE in *.wav; do sox -S --multi-threaded --buffer 131072 $FILE ${FILE%%.wav}.norm.wav noisered noise.prof 0.21 norm; done

# 4. re-insert audio into the videos.
# If you need to include an audio offset (+/- n seconds), add parameter "-itsoffset n" after the second -i parameter.
for FILE in *.norm.wav; do ffmpeg -i ${FILE%%.norm.wav}.mp4 -i $FILE -c:v copy -c:a aac -strict experimental -map 0:v:0 -map 1:a:0 ${FILE%%.norm.wav}.sync.mp4; done

# 5. Remove artefacts
rm -f *.wav noise.prof

# 6. That's it. You're done!
