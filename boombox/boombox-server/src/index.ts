export default {
	async fetch(request, env, ctx): Promise<Response> {
		console.log('Fetching audio data...');
		let url = new URL(request.url);
		let video = url.searchParams.get('video');

		if (!video) {
			console.log('No video provided');
			return new Response('No video provided', { status: 400 });
		}

		// Fetch video info...
		let videoInfo = fetch(`https://ytdlp.online/stream?command= --get-title ${video}`);
		console.log('Fetching video info in background...');

		console.log(`Fetching audio data... (${`https://ytdlp.online/stream?command= -x --audio-format mp3 ${video}`})`);
		let response = await fetch(`https://ytdlp.online/stream?command= -x --audio-format mp3 ${video}`);
		if (!response.ok) {
			console.log(`Failed to fetch audio data. (status: ${response.status} ${response.statusText})`);
			return new Response(`Failed to fetch audio data. (status: ${response.status} ${response.statusText})`, { status: response.status });
		}
		console.log(`Audio data fetched successfully`);
		let data = await response.text();
		console.log(data);
		let match = data.match(/<a href="([^]+)">/);
		if (!match) {
			console.log(`Failed to get mp3 video. Please try again.`);
			return new Response(`Failed to get mp3 video. Please try again.\n${data}`, { status: 500 });
		}
		let audioUrl = `https://ytdlp.online/${match[1].split('.mp3')[0]}.mp3`;

		console.log(`Fetching audio file... (${audioUrl})`);
		let audioResponse = await fetch(audioUrl);
		console.log(`Audio file fetched successfully`);
		if (!audioResponse.ok) {
			console.log(`Failed to fetch audio file. (status: ${audioResponse.status} ${audioResponse.statusText})`);
			return new Response(`Failed to fetch audio file. (status: ${audioResponse.status} ${audioResponse.statusText})`, { status: audioResponse.status });
		}
		let audioData = await audioResponse.arrayBuffer();

		console.log(`Uploading audio file...`);
		let fileInformation = await fetch('https://remote.craftos-pc.cc/music/upload', {
			method: 'POST',
			headers: {
				'Content-Type': 'application/octet-stream',
			},
			body: audioData,
		})
		if (fileInformation.headers.get('Content-Type')?.includes('application/json')) {
			console.log(`Failed to upload audio file. (status: ${fileInformation.status} ${fileInformation.statusText})`);
			return new Response(await fileInformation.text(), { status: 500 });
		}

		let fileId = await fileInformation.text();
		console.log(`Uploaded audio file successfully (id: ${fileId})`);

		let file = await fetch(`https://remote.craftos-pc.cc/music/content/${fileId}.wav`);
		if (!file.ok) {
			console.log(`Failed to fetch audio file. (status: ${file.status} ${file.statusText})`);
			return new Response(`Failed to fetch audio file. (status: ${file.status} ${file.statusText})`, { status: file.status });
		}
		let fileData = await file.arrayBuffer();

		console.log(`Fetched audio file successfully`);

		console.log('Processing video title')
		let videoInfoResult = await videoInfo
		let titleData = await videoInfoResult.text()
		let lines = titleData.split('\n')
		let title = lines.filter(line => line.startsWith('data'))[1]
		title = title.replace(': ', '');
		console.log(`Title: ${title}`)

		console.log(`Returning audio file...`);
		return new Response(fileData, {
			headers: {
				'Content-Type': 'audio/mpeg',
				'Content-Length': fileData.byteLength.toString(),
				'Content-Disposition': `attachment; filename="${title}.dfpwm.wav"`
			},
		});

	},
} satisfies ExportedHandler<Env>;
