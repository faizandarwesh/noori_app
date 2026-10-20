# Noori Stories — The First Five (Jungle) · ElevenLabs Scripts

These five stories were written before the recorded batches, so they had no script. This file is generated from the app's story files: the wording below is **exactly** what is on screen. Don't change any words, or the karaoke won't line up.

## How to make the audio

For each story and each language, make **two** generations in ElevenLabs:

1. **The story.** Paste the whole "Story" block in one go. Every paragraph is one scene and they're already in the order the app expects, with both choice branches included. Leave the blank lines between paragraphs: the tool cuts the recording in those pauses.
2. **The question.** Paste the one line under "Choice question" on its own. It plays when the child has to choose.

You can add ElevenLabs tags like `[warm]` or `[excited]` anywhere. They aren't spoken, so they don't affect the cutting. Don't add a title or an intro line.

Save the files like this:

| Generation | Save as |
|---|---|
| Story, Urdu | `audio_files/first5/<story id>_ur.mp3` |
| Story, English | `audio_files/first5/<story id>_en.mp3` |
| Question, Urdu | `assets/audio/stories/<story id>/ur/choice.mp3` |
| Question, English | `assets/audio/stories/<story id>/en/choice.mp3` |

Then, from the project folder, cut each story into pages (about 7 minutes per Urdu file, 1 minute per English one):

```
dart run tool/align_audio.dart <story id> --lang ur --split audio_files/first5/<story id>_ur.mp3 --whisper C:/whisper/bin/Release/whisper-cli.exe --model C:/whisper/ggml-large-v3.bin
dart run tool/align_audio.dart <story id> --lang en --split audio_files/first5/<story id>_en.mp3 --whisper C:/whisper/bin/Release/whisper-cli.exe --model C:/whisper/ggml-large-v3.bin
```

It prints one line per page. Every page should say "words heard". A page that says "not in the recording" stays silent: re-generate that story.

---

## Bunty and the Big Mango | بنٹی اور بڑا آم
Story id: `bunty_big_mango`

### Urdu

**Story** (9 scenes)

```
بنٹی خرگوش اچھلتا کودتا آم کے بڑے درخت کے پاس آیا۔

دھپ! ایک بڑا سا پیلا آم نیچے گرا۔ بنٹی بولا، “واہ، مزے دار!”

پھر ٹولو کچھوا آہستہ آہستہ آیا۔ ٹولو بولا، “مجھے بہت بھوک لگی ہے۔”

مٹھو طوطا بھی اڑ کر نیچے آ گیا۔ مٹھو نے پوچھا، “کیا یہ آم ہے؟”

بنٹی مسکرایا۔ “آؤ، مل کر کھاتے ہیں!” اس نے ہر دوست کو ایک ٹکڑا دیا۔

سب نے مل کر کھایا اور خوب ہنسے۔ آم اور بھی میٹھا لگا!

بنٹی نے اکیلے ہی سارا آم کھا لیا۔ اس کے دوست اداس ہو کر چلے گئے۔

بنٹی کو اکیلا پن محسوس ہوا۔ وہ بولا، “اگلی بار میں ضرور بانٹوں گا۔”

مل بانٹ کر کھانے سے سب کا دل خوش ہوتا ہے۔ ختم شد!
```

**Choice question**

```
بنٹی آم کا کیا کرے؟
```

### English

**Story** (9 scenes)

```
Bunty the rabbit hopped to the big mango tree.

Plop! A big yellow mango fell down. “Yum!” said Bunty.

Then Tolu the turtle came, slowly, slowly. “I am so hungry,” said Tolu.

Mithu the parrot flew down too. “Is that a mango?” asked Mithu.

Bunty smiled. “Let's share!” He gave each friend a piece.

They ate and laughed together. The mango tasted extra sweet!

Bunty ate the mango all alone. His friends went away, feeling sad.

Bunty felt lonely. “Next time, I will share,” he said.

Sharing makes every heart happy. The end!
```

**Choice question**

```
What should Bunty do with the mango?
```

<details><summary>Scene order (for reference)</summary>

- `p1`: Bunty the rabbit hopped to the big mango tree.
- `p2`: Plop! A big yellow mango fell down. “Yum!” said Bunty.
- `p3`: Then Tolu the turtle came, slowly, slowly. “I am so hungry,” said Tolu.
- `p4`: Mithu the parrot flew down too. “Is that a mango?” asked Mithu.
- `p5_share` — branch "Share it": Bunty smiled. “Let's share!” He gave each friend a piece.
- `p6_share` — branch "Share it": They ate and laughed together. The mango tasted extra sweet!
- `p5_keep` — branch "Keep it all": Bunty ate the mango all alone. His friends went away, feeling sad.
- `p6_keep` — branch "Keep it all": Bunty felt lonely. “Next time, I will share,” he said.
- `p7`: Sharing makes every heart happy. The end!

</details>

---

## Gulu's Gentle Trunk | گولو کی پیاری سونڈ
Story id: `gulu_gentle_trunk`

### Urdu

**Story** (9 scenes)

```
گولو ہاتھی دریا کے کنارے دھم دھم چلا جا رہا تھا۔

“چوں چوں!” چڑیا کا ننھا بچہ اپنے گھونسلے سے نیچے گر گیا تھا۔

امی چڑیا گول گول اڑنے لگی۔ “میرا بچہ ابھی اڑ نہیں سکتا!”

گھونسلا درخت پر بہت اونچا تھا۔ ننھے بچے کے لیے بہت ہی اونچا!

گولو نے اپنی نرم سونڈ سے بچے کو اٹھایا۔ آرام سے، آرام سے۔

اس نے بچے کو واپس گھونسلے میں رکھ دیا۔ امی چڑیا گا کر بولی، “شکریہ گولو!”

گولو آگے چلا گیا۔ لیکن اسے ننھے بچے کا خیال آتا رہا۔

وہ واپس آیا اور سونڈ سے بچے کو گھونسلے تک پہنچا دیا۔ مہربانی کر کے بہت اچھا لگا!

مہربان دل سے سارا جنگل مسکرا اٹھتا ہے۔ ختم شد!
```

**Choice question**

```
گولو کو کیا کرنا چاہیے؟
```

### English

**Story** (9 scenes)

```
Gulu the elephant was walking by the river. Stomp, stomp!

“Peep! Peep!” A baby bird had fallen from its nest.

Mama Bird flew round and round. “My baby can't fly yet!”

The nest was high up in the tree. Too high for the little bird!

Gulu lifted the baby bird with his soft trunk. Gently, gently.

He put it back in its nest. “Thank you, Gulu!” sang Mama Bird.

Gulu walked away. But he kept thinking about the little bird.

He turned back and lifted it home with his trunk. Being kind felt good!

A kind heart makes the whole jungle smile. The end!
```

**Choice question**

```
What should Gulu do?
```

<details><summary>Scene order (for reference)</summary>

- `p1`: Gulu the elephant was walking by the river. Stomp, stomp!
- `p2`: “Peep! Peep!” A baby bird had fallen from its nest.
- `p3`: Mama Bird flew round and round. “My baby can't fly yet!”
- `p4`: The nest was high up in the tree. Too high for the little bird!
- `p5_help` — branch "Help the baby bird": Gulu lifted the baby bird with his soft trunk. Gently, gently.
- `p6_help` — branch "Help the baby bird": He put it back in its nest. “Thank you, Gulu!” sang Mama Bird.
- `p5_away` — branch "Walk away": Gulu walked away. But he kept thinking about the little bird.
- `p6_away` — branch "Walk away": He turned back and lifted it home with his trunk. Being kind felt good!
- `p7`: A kind heart makes the whole jungle smile. The end!

</details>

---

## Mithu Tells the Truth | مٹھو نے سچ بولا
Story id: `mithu_tells_truth`

### Urdu

**Story** (9 scenes)

```
مٹھو طوطے کو اپنی لال گیند سے کھیلنا بہت پسند تھا۔

ٹپ، ٹپ! اوہو! گیند گولو کے پھولوں والے گملے سے جا ٹکرائی۔

چھن! گملا ٹوٹ کر ٹکڑے ٹکڑے ہو گیا۔ مٹھو ڈر گیا۔

گولو ہاتھی وہاں آیا۔ “ارے! میرا گملا کس نے توڑا؟”

مٹھو نے آہستہ سے کہا، “یہ میں نے کیا۔ معاف کرنا، گولو۔”

گولو مسکرایا۔ “سچ بتانے کا شکریہ۔ آؤ مل کر ٹھیک کرتے ہیں!”

مٹھو ایک جھاڑی کے پیچھے چھپ گیا۔ اس کا دل عجیب سا اور اداس ہو گیا۔

پھر وہ باہر آیا۔ “یہ میں نے کیا۔ معاف کرنا۔” گولو نے اسے گلے لگا لیا۔

دونوں نے پھول نئے گملے میں لگائے۔ سچ بولنے سے دل ہلکا ہو جاتا ہے۔ ختم شد!
```

**Choice question**

```
مٹھو کو کیا کرنا چاہیے؟
```

### English

**Story** (9 scenes)

```
Mithu the parrot loved to play with his red ball.

Bounce, bounce! Oops! The ball hit Gulu's flower pot.

Crash! The pot broke into pieces. Mithu felt scared.

Gulu the elephant came by. “Oh no! Who broke my pot?”

“It was me. I'm sorry, Gulu,” said Mithu softly.

Gulu smiled. “Thank you for telling the truth. Let's fix it together!”

Mithu hid behind a bush. His tummy felt funny and sad.

Then he came out. “It was me. I'm sorry.” Gulu gave him a big hug.

They planted the flowers in a new pot. Telling the truth feels good. The end!
```

**Choice question**

```
What should Mithu do?
```

<details><summary>Scene order (for reference)</summary>

- `p1`: Mithu the parrot loved to play with his red ball.
- `p2`: Bounce, bounce! Oops! The ball hit Gulu's flower pot.
- `p3`: Crash! The pot broke into pieces. Mithu felt scared.
- `p4`: Gulu the elephant came by. “Oh no! Who broke my pot?”
- `p5_truth` — branch "Tell the truth": “It was me. I'm sorry, Gulu,” said Mithu softly.
- `p6_truth` — branch "Tell the truth": Gulu smiled. “Thank you for telling the truth. Let's fix it together!”
- `p5_hide` — branch "Hide": Mithu hid behind a bush. His tummy felt funny and sad.
- `p6_hide` — branch "Hide": Then he came out. “It was me. I'm sorry.” Gulu gave him a big hug.
- `p7`: They planted the flowers in a new pot. Telling the truth feels good. The end!

</details>

---

## Tolu and the Tiny Seed | ٹولو اور ننھا بیج
Story id: `tolu_tiny_seed`

### Urdu

**Story** (9 scenes)

```
ٹولو کچھوے کو ایک ننھا سا بھورا بیج ملا۔

اس نے بیج کو مٹی میں بویا اور تھوڑا سا پانی دیا۔

اگلی صبح ٹولو نے خوب دیکھا۔ پودا تو ابھی نکلا ہی نہیں!

ٹولو نے پوچھا، “یہ کب اگے گا؟” بنٹی بولا، “بیج کو وقت چاہیے۔”

ٹولو نے انتظار کیا۔ وہ ہر روز بیج کو تھوڑا سا پانی دیتا۔

ایک دن ایک ننھی سی ہری کونپل نکل آئی! ٹولو بہت خوش ہوا۔

ٹولو نے بیج کھود کر دیکھا۔ وہ تو ابھی بھی بس ایک بیج تھا!

اس نے بیج دوبارہ بویا اور انتظار کیا۔ جلد ہی ایک ننھی کونپل نکل آئی۔

اب وہاں ایک بڑا سا پھول کھلتا ہے۔ اچھی چیزوں میں وقت لگتا ہے۔ ختم شد!
```

**Choice question**

```
ٹولو کو کیا کرنا چاہیے؟
```

### English

**Story** (9 scenes)

```
Tolu the turtle found a tiny brown seed.

He planted it in the soil and gave it some water.

The next morning, Tolu looked and looked. No plant yet!

“When will it grow?” asked Tolu. “Seeds need time,” said Bunty.

Tolu waited. Every day, he gave the seed a little water.

One day, a tiny green sprout popped up! Tolu was so happy.

Tolu dug up the seed to look. It was still just a seed!

He planted it again and waited. Soon, a little sprout came up.

Now a big flower grows there. Good things take time. The end!
```

**Choice question**

```
What should Tolu do?
```

<details><summary>Scene order (for reference)</summary>

- `p1`: Tolu the turtle found a tiny brown seed.
- `p2`: He planted it in the soil and gave it some water.
- `p3`: The next morning, Tolu looked and looked. No plant yet!
- `p4`: “When will it grow?” asked Tolu. “Seeds need time,” said Bunty.
- `p5_wait` — branch "Wait and water it": Tolu waited. Every day, he gave the seed a little water.
- `p6_wait` — branch "Wait and water it": One day, a tiny green sprout popped up! Tolu was so happy.
- `p5_dig` — branch "Dig it up to look": Tolu dug up the seed to look. It was still just a seed!
- `p6_dig` — branch "Dig it up to look": He planted it again and waited. Soon, a little sprout came up.
- `p7`: Now a big flower grows there. Good things take time. The end!

</details>

---

## Chunnu Crosses the River | چُنّو نے دریا پار کیا
Story id: `chunnu_crosses_river`

### Urdu

**Story** (9 scenes)

```
چُنّو بندر دریا کے پار گولو سے ملنا چاہتا تھا۔

لیکن دریا بہت چوڑا تھا، اور پانی شوں شوں کر کے بہہ رہا تھا!

پانی میں بڑے بڑے پتھر تھے۔ ایک، دو، تین!

چُنّو کے گھٹنے کانپنے لگے۔ وہ بولا، “مجھے ڈر لگ رہا ہے۔”

چُنّو نے لمبی سانس لی۔ پھدک! پھدک! پھدک! وہ پتھروں پر سے گزرنے لگا۔

وہ پہنچ گیا! گولو نے اپنے بڑے کان ہلائے۔ “تم تو بہت بہادر ہو!”

چُنّو گھر چلا گیا۔ لیکن اس کا اپنے دوست سے ملنے کو بہت دل چاہ رہا تھا۔

اگلے دن وہ واپس آیا، لمبی سانس لی، اور پھدک پھدک کر پار ہو گیا!

بہادری کا مطلب ہے ڈر لگے تب بھی کوشش کرنا۔ ختم شد!
```

**Choice question**

```
چُنّو کو کیا کرنا چاہیے؟
```

### English

**Story** (9 scenes)

```
Chunnu the monkey wanted to visit Gulu across the river.

But the river was wide, and the water went whoosh, whoosh!

There were big stones in the water. One, two, three!

Chunnu's knees went wobble, wobble. “I'm scared,” he said.

Chunnu took a big breath. Hop! Hop! Hop! Over the stones he went.

He made it! Gulu flapped his big ears. “You were so brave!”

Chunnu went home. But he still wanted to see his friend.

The next day, he came back, took a big breath, and hopped across!

Being brave means trying, even when you feel scared. The end!
```

**Choice question**

```
What should Chunnu do?
```

<details><summary>Scene order (for reference)</summary>

- `p1`: Chunnu the monkey wanted to visit Gulu across the river.
- `p2`: But the river was wide, and the water went whoosh, whoosh!
- `p3`: There were big stones in the water. One, two, three!
- `p4`: Chunnu's knees went wobble, wobble. “I'm scared,” he said.
- `p5_try` — branch "Try, step by step": Chunnu took a big breath. Hop! Hop! Hop! Over the stones he went.
- `p6_try` — branch "Try, step by step": He made it! Gulu flapped his big ears. “You were so brave!”
- `p5_home` — branch "Go back home": Chunnu went home. But he still wanted to see his friend.
- `p6_home` — branch "Go back home": The next day, he came back, took a big breath, and hopped across!
- `p7`: Being brave means trying, even when you feel scared. The end!

</details>

