# Noori Stories — Batch 2 & 3 (Stories 6–15)

Original stories for Noori. Ages 3–8. English + Urdu (natural, simple spoken Urdu).
- **Zone 2: Ghar (Home)** → Stories 6–10
- **Zone 3: Samandar (Sea)** → Stories 11–15

## Notes for Claude Code
- Words in `[square brackets]` are **ElevenLabs audio tags** (e.g. `[warm]`, `[short pause]`). Keep them out of on-screen text and karaoke: strip every `[...]` before display.
- Audio is generated **per part**, not per scene. Each story has 4 audio files per language:
  - `s06_en_part1.mp3` (scenes before the choice, ending with the question)
  - `s06_en_choice_a.mp3`, `s06_en_choice_b.mp3`
  - `s06_en_part2.mp3` (scenes after the choice)
  - Same pattern for Urdu: `s06_ur_part1.mp3`, etc.
- Each `S#:` line is one scene (one illustration). Use Whisper word timestamps (`tools/align_audio.py`) to find where each scene starts and ends inside a part's audio, then auto-advance the illustration at that point.
- Both choice branches lead back to the good path, with no shaming.

---

## Story 6: Zoya's Messy Room | زویا کا بکھرا کمرہ
**Zone:** Ghar · **Value:** Cleanliness (صفائی) · **Characters:** Zoya (5, yellow frock), her doll Rani, Ammi

**Illustrations**
1. Zoya's room with toys everywhere; Zoya in the middle, smiling.
2. Ammi at the door, holding Zoya's shoes, ready for the park.
3. Zoya searching under blocks and balls, worried face.
4. Zoya sitting among the mess, thinking. (choice)
5. Clean room; under a pile of clothes, Rani's little face peeks out.
6. Ammi kneeling, smiling at Zoya.
7. Zoya and Rani on a park swing, sunny day.
8. Night: tidy room, toys on shelves, Zoya in bed waving at them.

**English**

*Part 1*
- S1: [happy] Zoya loved her toys. Blocks, balls, crayons, and her doll, Rani. [playfully] But her room was a big mess! Toys here, toys there, toys everywhere!
- S2: [warm] Ammi called, "Zoya, let's go to the park! Bring Rani with you." [excited] "Yay!" said Zoya.
- S3: [curious] Zoya looked for Rani. Under the blocks? No. Behind the balls? No. [sad] "Where is Rani?" She could not find her anywhere.
- S4: [thoughtful] The room was so messy. Zoya could clean up and look again, or she could sit down and cry. [short pause] [curious] What should Zoya do?

*Choice A: Clean up*
[excited] "I will clean up!" said Zoya. Blocks in the box. Balls in the basket. Crayons in the cup. [happy] One by one, the room became neat and clean.

*Choice B: Sit and cry*
[sad] Zoya sat down and started to cry. [short pause] [softly] Then she wiped her tears. "Crying won't find Rani. I will clean up!" [happy] Blocks in the box, balls in the basket. Soon the room was neat and clean.

*Part 2*
- S5: [gasps] And look! Under the pile of clothes, there was Rani! [laughs] "Rani! I found you!" Zoya gave her a big hug.
- S6: [warm] Ammi smiled. "Masha Allah, Zoya! Allah loves cleanliness. And in a clean room, nothing gets lost."
- S7: [happy] Zoya took Rani to the park. They played on the swings for a long time. [laughs] Wheee! So much fun!
- S8: [softly] That night, Zoya put her toys back in their places. [whispers] "Good night, toys." [warm] "See you tomorrow!"

**Urdu**

*Part 1*
- S1: [happy] زویا کو اپنے کھلونے بہت پسند تھے۔ بلاکس، گیندیں، رنگ، اور اس کی گڑیا، رانی۔ [playfully] مگر اس کا کمرہ بہت بکھرا ہوا تھا! یہاں کھلونے، وہاں کھلونے، ہر طرف کھلونے!
- S2: [warm] امی نے آواز دی، "زویا، چلو پارک چلیں! رانی کو بھی ساتھ لے آؤ۔" [excited] "واہ!" زویا نے کہا۔
- S3: [curious] زویا نے رانی کو ڈھونڈا۔ بلاکس کے نیچے؟ نہیں۔ گیندوں کے پیچھے؟ نہیں۔ [sad] "رانی کہاں ہے؟" وہ کہیں نہیں ملی۔
- S4: [thoughtful] کمرہ بہت بکھرا ہوا تھا۔ زویا صفائی کر کے دوبارہ ڈھونڈ سکتی تھی، یا بیٹھ کر رو سکتی تھی۔ [short pause] [curious] زویا کو کیا کرنا چاہیے؟

*Choice A*
[excited] "میں صفائی کروں گی!" زویا نے کہا۔ بلاکس ڈبے میں۔ گیندیں ٹوکری میں۔ رنگ کپ میں۔ [happy] ایک ایک کر کے کمرہ صاف ستھرا ہو گیا۔

*Choice B*
[sad] زویا بیٹھ کر رونے لگی۔ [short pause] [softly] پھر اس نے آنسو پونچھے۔ "رونے سے رانی نہیں ملے گی۔ میں صفائی کروں گی!" [happy] بلاکس ڈبے میں، گیندیں ٹوکری میں۔ جلدی ہی کمرہ صاف ستھرا ہو گیا۔

*Part 2*
- S5: [gasps] اور یہ دیکھو! کپڑوں کے ڈھیر کے نیچے رانی تھی! [laughs] "رانی! تم مل گئیں!" زویا نے اسے زور سے گلے لگا لیا۔
- S6: [warm] امی مسکرائیں۔ "ماشاءاللہ زویا! اللہ تعالیٰ کو صفائی پسند ہے۔ اور صاف کمرے میں کوئی چیز گم نہیں ہوتی۔"
- S7: [happy] زویا رانی کو لے کر پارک گئی۔ دونوں نے خوب جھولا جھولا۔ [laughs] واہ، کتنا مزہ آیا!
- S8: [softly] اس رات زویا نے سارے کھلونے ان کی جگہ پر رکھے۔ [whispers] "شب بخیر، کھلونو۔" [warm] "کل ملیں گے!"

**Quiz**
1. Who is Rani? | رانی کون ہے؟ → 🪆 A doll ✅ · 🐱 A cat · 🐦 A bird
2. Where did the blocks go? | بلاکس کہاں گئے؟ → 📦 In the box ✅ · 🛏️ Under the bed · 🚪 Outside
3. Where did Zoya and Rani go? | زویا اور رانی کہاں گئیں؟ → 🛝 The park ✅ · 🏫 School · 🏪 A shop

**New words:** clean / صاف · toy / کھلونا · doll / گڑیا

---

## Story 7: Dada Jaan's Glasses | دادا جان کی عینک
**Zone:** Ghar · **Value:** Respecting and helping elders · **Characters:** Ahmed (6, green kurta), Dada Jaan (white beard, brown sweater)

**Illustrations**
1. Dada Jaan in his armchair with a book, smiling at Ahmed.
2. Ahmed on the carpet laughing at the TV.
3. Dada Jaan patting his pockets, puzzled.
4. Ahmed looking between the TV and Dada Jaan. (choice)
5. Ahmed checking under the sofa cushion.
6. Close-up: the glasses sitting on top of Dada Jaan's head; both laughing.
7. Dada Jaan hugging Ahmed.
8. Ahmed on Dada Jaan's lap, both reading the book in warm lamp light.

**English**

*Part 1*
- S1: [warm] Ahmed loved his Dada Jaan. Dada Jaan had a white beard and the kindest smile.
- S2: [happy] One evening, Ahmed was watching cartoons. [laughs] Ha ha! The cartoon was so funny!
- S3: [concerned] Then Dada Jaan called, "Ahmed beta, I can't find my glasses. Without them, I can't read my book."
- S4: [thoughtful] Ahmed looked at the TV. The cartoon was at the best part! [short pause] [curious] What should Ahmed do?

*Choice A: Help right away*
[warm] Ahmed switched off the TV right away. "I'm coming, Dada Jaan! I will help you find them."

*Choice B: Keep watching*
[playfully] "Just one minute, Dada Jaan!" said Ahmed. [short pause] [thoughtful] But then he thought, "Dada Jaan needs me now." [warm] He switched off the TV. "I'm coming, Dada Jaan!"

*Part 2*
- S5: [curious] Ahmed looked on the table. No glasses. Under the sofa? No glasses. [short pause] Then he looked up at Dada Jaan. [giggles]
- S6: [laughs] "Dada Jaan! Your glasses are on your head!" Dada Jaan touched his head and laughed too. "Oh ho! They were with me all along!"
- S7: [warm] Dada Jaan hugged Ahmed. "JazakAllah, beta. When we help our elders, Allah is happy with us."
- S8: [softly] Then Dada Jaan read Ahmed a story from his book. [happy] It was even better than the cartoon!

**Urdu**

*Part 1*
- S1: [warm] احمد کو اپنے دادا جان سے بہت پیار تھا۔ دادا جان کی سفید داڑھی تھی اور بہت پیاری مسکراہٹ۔
- S2: [happy] ایک شام احمد کارٹون دیکھ رہا تھا۔ [laughs] ہا ہا! کارٹون بہت مزے کا تھا!
- S3: [concerned] تب دادا جان نے آواز دی، "احمد بیٹا، میری عینک نہیں مل رہی۔ عینک کے بغیر میں اپنی کتاب نہیں پڑھ سکتا۔"
- S4: [thoughtful] احمد نے ٹی وی کی طرف دیکھا۔ کارٹون سب سے مزے والی جگہ پر تھا! [short pause] [curious] احمد کو کیا کرنا چاہیے؟

*Choice A*
[warm] احمد نے فوراً ٹی وی بند کیا۔ "آیا دادا جان! میں آپ کی عینک ڈھونڈنے میں مدد کرتا ہوں۔"

*Choice B*
[playfully] "بس ایک منٹ، دادا جان!" احمد نے کہا۔ [short pause] [thoughtful] پھر اس نے سوچا، "دادا جان کو ابھی میری ضرورت ہے۔" [warm] اس نے ٹی وی بند کیا۔ "آیا دادا جان!"

*Part 2*
- S5: [curious] احمد نے میز پر دیکھا۔ عینک نہیں تھی۔ صوفے کے نیچے؟ وہاں بھی نہیں۔ [short pause] پھر اس نے دادا جان کی طرف دیکھا۔ [giggles]
- S6: [laughs] "دادا جان! عینک تو آپ کے سر پر ہے!" دادا جان نے سر پر ہاتھ رکھا اور ہنس پڑے۔ "ارے واہ! عینک تو میرے پاس ہی تھی!"
- S7: [warm] دادا جان نے احمد کو گلے لگایا۔ "جزاک اللہ بیٹا۔ جب ہم بڑوں کی مدد کرتے ہیں تو اللہ تعالیٰ ہم سے خوش ہوتے ہیں۔"
- S8: [softly] پھر دادا جان نے احمد کو اپنی کتاب سے ایک کہانی سنائی۔ [happy] وہ کارٹون سے بھی زیادہ مزے کی تھی!

**Quiz**
1. What did Dada Jaan lose? | دادا جان کی کیا چیز گم ہوئی؟ → 👓 Glasses ✅ · 👟 Shoes · 🔑 Keys
2. Where were the glasses? | عینک کہاں تھی؟ → 👴 On his head ✅ · 🛋️ Under the sofa · 🍳 In the kitchen
3. What did they do at the end? | آخر میں انہوں نے کیا کیا؟ → 📖 Read a story ✅ · 📺 Watched TV · 😴 Slept

**New words:** glasses / عینک · help / مدد · elders / بڑے

---

## Story 8: Sara the Iftar Helper | سارہ کی افطاری
**Zone:** Ghar · **Value:** Helping parents · **Characters:** Sara (6, purple dupatta), Ammi, Abbu, Sara's friends

**Illustrations**
1. Evening home decorated with a crescent moon and small lights.
2. Ammi in the kitchen frying pakoras, wiping her forehead.
3. Sara's friends at the window, waving her outside.
4. Sara between the window and the kitchen. (choice)
5. Sara placing dates in a bowl; dastarkhwan with plates, glasses, sharbat.
6. Family seated on the dastarkhwan; Abbu holding a date.
7. Ammi smiling at Sara, hand on her head.
8. Sara beaming, holding an empty plate, ready to help again.

**English**

*Part 1*
- S1: [warm] It was Ramzan. Ammi and Abbu were fasting. [happy] Sara was too little to fast, but she loved Iftar time!
- S2: [softly] In the kitchen, Ammi was making pakoras and fruit chaat. She looked very tired.
- S3: [playfully] Outside, Sara's friends were playing. "Sara, come and play!" they called.
- S4: [thoughtful] Sara looked at her friends. Then she looked at tired Ammi. [short pause] [curious] What should Sara do?

*Choice A: Help Ammi*
[warm] "Ammi, let me help you!" said Sara. She put the plates and glasses on the dastarkhwan, one by one.

*Choice B: Go and play*
[happy] Sara ran outside to play. [short pause] [thoughtful] But she kept thinking of Ammi. She came back in. "Ammi, let me help you!" She put the plates and glasses on the dastarkhwan.

*Part 2*
- S5: [excited] Sara washed the dates and put them in a bowl. She poured sharbat into the glasses. [happy] The dastarkhwan looked so pretty!
- S6: [calm] Then they heard the azan. [softly] Abbu said, "Bismillah," and everyone opened their fast with a date.
- S7: [warm] Ammi smiled at Sara. "JazakAllah, my little helper. You made my work so easy today."
- S8: [happy] Sara felt so happy inside. Helping Ammi was even more fun than playing! [laughs] "Can I help tomorrow too?"

**Urdu**

*Part 1*
- S1: [warm] رمضان کا مہینہ تھا۔ امی اور ابو روزے سے تھے۔ [happy] سارہ ابھی چھوٹی تھی، مگر اسے افطاری کا وقت بہت پسند تھا!
- S2: [softly] کچن میں امی پکوڑے اور فروٹ چاٹ بنا رہی تھیں۔ وہ بہت تھکی ہوئی لگ رہی تھیں۔
- S3: [playfully] باہر سارہ کی سہیلیاں کھیل رہی تھیں۔ "سارہ، آؤ کھیلیں!" انہوں نے آواز دی۔
- S4: [thoughtful] سارہ نے سہیلیوں کی طرف دیکھا۔ پھر تھکی ہوئی امی کو دیکھا۔ [short pause] [curious] سارہ کو کیا کرنا چاہیے؟

*Choice A*
[warm] "امی، میں آپ کی مدد کرتی ہوں!" سارہ نے کہا۔ اس نے ایک ایک کر کے پلیٹیں اور گلاس دسترخوان پر رکھے۔

*Choice B*
[happy] سارہ کھیلنے کے لیے باہر بھاگی۔ [short pause] [thoughtful] مگر اسے امی کا خیال آتا رہا۔ وہ واپس آئی۔ "امی، میں آپ کی مدد کرتی ہوں!" اس نے پلیٹیں اور گلاس دسترخوان پر رکھے۔

*Part 2*
- S5: [excited] سارہ نے کھجوریں دھو کر پیالے میں رکھیں۔ اس نے گلاسوں میں شربت ڈالا۔ [happy] دسترخوان بہت پیارا لگ رہا تھا!
- S6: [calm] پھر اذان کی آواز آئی۔ [softly] ابو نے "بسم اللہ" کہا اور سب نے کھجور سے روزہ کھولا۔
- S7: [warm] امی سارہ کو دیکھ کر مسکرائیں۔ "جزاک اللہ، میری ننھی مددگار۔ آج تم نے میرا کام بہت آسان کر دیا۔"
- S8: [happy] سارہ کو اندر سے بہت خوشی ہوئی۔ امی کی مدد کرنا کھیلنے سے بھی زیادہ مزے کا تھا! [laughs] "کیا میں کل بھی مدد کروں؟"

**Quiz**
1. Which month was it? | کون سا مہینہ تھا؟ → 🌙 Ramzan ✅ · ❄️ Winter holidays · 🎂 Birthday month
2. What did they open their fast with? | سب نے روزہ کس سے کھولا؟ → 🌴 Dates ✅ · 🍦 Ice cream · 🍕 Pizza
3. Who did Sara help? | سارہ نے کس کی مدد کی؟ → 👩 Ammi ✅ · 🐱 A cat · 🧸 Her teddy

**New words:** helper / مددگار · dates / کھجور · fast / روزہ

---

## Story 9: Usman Asks First | عثمان پہلے پوچھتا ہے
**Zone:** Ghar · **Value:** Asking permission, saying thank you · **Characters:** Usman (5, red cap), his cousin Rayan (6), Ammi

**Illustrations**
1. Rayan at the door holding a shiny red toy car; Usman excited.
2. The red car zooming across the floor; Usman's eyes wide.
3. Car alone on the floor; Rayan walking to the kitchen for water.
4. Usman reaching toward the car, then pausing. (choice)
5. Rayan smiling, handing the car to Usman.
6. Both boys building a road from books and blocks; car on a ramp.
7. Ammi watching from the doorway, smiling.
8. Usman handing the car back; both waving goodbye.

**English**

*Part 1*
- S1: [excited] Usman's cousin Rayan came to visit. He brought a shiny new toy car! [playfully] Vroom, vroom!
- S2: [happy] The car was red and very fast. It zoomed across the floor. Usman's eyes went big. [whispers] "Wow!"
- S3: [curious] Rayan put the car down and went to drink water. The car was right there, all alone.
- S4: [thoughtful] Usman really wanted to play with it. He could just take it, or he could ask Rayan first. [short pause] [curious] What should Usman do?

*Choice A: Ask first*
[warm] Usman waited for Rayan. [softly] "Rayan, please, can I play with your car?"

*Choice B: Just take it*
[nervous] Usman picked up the car. But his heart said, "This is not mine." [short pause] [softly] He put it back and waited. "Rayan, please, can I play with your car?"

*Part 2*
- S5: [happy] Rayan smiled. "Of course! Thank you for asking. Let's play together!"
- S6: [excited] They built a road with books and blocks. The red car zoomed up the hill and down again! [laughs] Vroom!
- S7: [warm] Ammi was watching. "Masha Allah, Usman. When we ask first, everyone feels happy."
- S8: [happy] When it was time to go, Usman gave the car back. "Thank you, Rayan!" [laughs] "Next time, come to my house and we'll play again!" said Rayan.

**Urdu**

*Part 1*
- S1: [excited] عثمان کا کزن ریان ملنے آیا۔ وہ ایک چمکتی ہوئی نئی کھلونا گاڑی لایا تھا! [playfully] ووم، ووم!
- S2: [happy] گاڑی لال رنگ کی تھی اور بہت تیز چلتی تھی۔ وہ فرش پر تیزی سے دوڑی۔ عثمان کی آنکھیں بڑی ہو گئیں۔ [whispers] "واہ!"
- S3: [curious] ریان گاڑی رکھ کر پانی پینے چلا گیا۔ گاڑی وہیں اکیلی پڑی تھی۔
- S4: [thoughtful] عثمان کا بہت دل چاہ رہا تھا کہ وہ گاڑی سے کھیلے۔ وہ اسے ایسے ہی اٹھا سکتا تھا، یا پہلے ریان سے پوچھ سکتا تھا۔ [short pause] [curious] عثمان کو کیا کرنا چاہیے؟

*Choice A*
[warm] عثمان نے ریان کا انتظار کیا۔ [softly] "ریان، کیا میں تمہاری گاڑی سے کھیل سکتا ہوں؟"

*Choice B*
[nervous] عثمان نے گاڑی اٹھا لی۔ مگر اس کے دل نے کہا، "یہ میری نہیں ہے۔" [short pause] [softly] اس نے گاڑی واپس رکھی اور انتظار کیا۔ "ریان، کیا میں تمہاری گاڑی سے کھیل سکتا ہوں؟"

*Part 2*
- S5: [happy] ریان مسکرایا۔ "ہاں ضرور! پوچھنے کا شکریہ۔ چلو مل کر کھیلتے ہیں!"
- S6: [excited] دونوں نے کتابوں اور بلاکس سے ایک سڑک بنائی۔ لال گاڑی اوپر گئی اور پھر نیچے آئی! [laughs] ووم!
- S7: [warm] امی دیکھ رہی تھیں۔ "ماشاءاللہ عثمان۔ جب ہم پہلے پوچھتے ہیں تو سب خوش ہوتے ہیں۔"
- S8: [happy] جانے کا وقت ہوا تو عثمان نے گاڑی واپس کر دی۔ "شکریہ ریان!" [laughs] "اگلی بار میرے گھر آنا، پھر کھیلیں گے!" ریان نے کہا۔

**Quiz**
1. What toy did Rayan bring? | ریان کون سا کھلونا لایا؟ → 🚗 A car ✅ · 🪁 A kite · 🧸 A teddy
2. What did Usman do before playing? | کھیلنے سے پہلے عثمان نے کیا کیا؟ → 🙋 Asked ✅ · 🏃 Ran away · 😭 Cried
3. What did they build? | انہوں نے کیا بنایا؟ → 🛣️ A road ✅ · 🏰 A castle · 🚀 A rocket

**New words:** car / گاڑی · ask / پوچھنا · thank you / شکریہ

---

## Story 10: Fatima Is Not Afraid | فاطمہ اب نہیں ڈرتی
**Zone:** Ghar · **Value:** Courage, Allah is always with us · **Characters:** Fatima (5, star pajamas), Ammi

**Illustrations**
1. Dark bedroom, moonlight through the window, Fatima in bed.
2. A tree branch tapping the window; Fatima's eyes wide.
3. A big wiggly shadow on the wall; Fatima holding her blanket.
4. Fatima half under her blanket, thinking. (choice)
5. Ammi pulling the curtain open; a friendly tree swaying in the wind.
6. Fatima giggling, pointing at the dancing shadow.
7. Ammi sitting on the bed, holding Fatima's hand.
8. Fatima asleep with a smile; soft glow, branch gently tapping.

**English**

*Part 1*
- S1: [softly] It was night time. Fatima was in her bed. The lights were off and the room was dark.
- S2: [nervous] Tap, tap, tap. Fatima heard a sound at the window. [whispers] "What is that?"
- S3: [nervous] On the wall, there was a big, wiggly shadow. Fatima's heart went thump, thump.
- S4: [thoughtful] Fatima could hide under her blanket and cry. Or she could call Ammi and be brave. [short pause] [curious] What should Fatima do?

*Choice A: Call Ammi*
[softly] Fatima took a deep breath. "Ammi! Can you come, please?" Ammi came in with a soft smile.

*Choice B: Hide under the blanket*
[sad] Fatima hid under her blanket. [short pause] [softly] But it was so hot in there! She peeked out. "Ammi! Can you come, please?" Ammi came in with a soft smile.

*Part 2*
- S5: [warm] Ammi opened the curtain. [laughs] "Look, Fatima! It's just the tree. Its branch is tapping the window, and the wind is making it dance."
- S6: [giggles] Fatima giggled. "The shadow is the tree dancing!" [happy] It wasn't scary at all.
- S7: [softly] Ammi sat next to her. "Remember, Fatima, Allah is always with us, even in the dark. Let's say Bismillah and close our eyes."
- S8: [whispers] "Bismillah," whispered Fatima. She closed her eyes and smiled. [softly] Tap, tap, went the tree. [calm] But Fatima was already fast asleep.

**Urdu**

*Part 1*
- S1: [softly] رات کا وقت تھا۔ فاطمہ اپنے بستر پر لیٹی تھی۔ بتیاں بند تھیں اور کمرے میں اندھیرا تھا۔
- S2: [nervous] ٹھک، ٹھک، ٹھک۔ فاطمہ نے کھڑکی پر ایک آواز سنی۔ [whispers] "یہ کیا ہے؟"
- S3: [nervous] دیوار پر ایک بڑا سا ہلتا ہوا سایہ تھا۔ فاطمہ کا دل دھک دھک کرنے لگا۔
- S4: [thoughtful] فاطمہ کمبل میں چھپ کر رو سکتی تھی۔ یا امی کو بلا کر بہادر بن سکتی تھی۔ [short pause] [curious] فاطمہ کو کیا کرنا چاہیے؟

*Choice A*
[softly] فاطمہ نے گہری سانس لی۔ "امی! ذرا آئیں نا!" امی مسکراتی ہوئی کمرے میں آئیں۔

*Choice B*
[sad] فاطمہ کمبل کے اندر چھپ گئی۔ [short pause] [softly] مگر اندر بہت گرمی تھی! اس نے باہر جھانکا۔ "امی! ذرا آئیں نا!" امی مسکراتی ہوئی کمرے میں آئیں۔

*Part 2*
- S5: [warm] امی نے پردہ ہٹایا۔ [laughs] "دیکھو فاطمہ! یہ تو درخت ہے۔ اس کی ٹہنی کھڑکی سے لگ رہی ہے، اور ہوا اسے نچا رہی ہے۔"
- S6: [giggles] فاطمہ ہنس پڑی۔ "سایہ تو درخت کا ناچ ہے!" [happy] اب وہ بالکل بھی ڈراؤنا نہیں لگ رہا تھا۔
- S7: [softly] امی اس کے پاس بیٹھ گئیں۔ "یاد رکھو فاطمہ، اللہ تعالیٰ ہر وقت ہمارے ساتھ ہیں، اندھیرے میں بھی۔ چلو بسم اللہ پڑھ کر آنکھیں بند کرتے ہیں۔"
- S8: [whispers] "بسم اللہ،" فاطمہ نے آہستہ سے کہا۔ اس نے آنکھیں بند کیں اور مسکرا دی۔ [softly] ٹھک، ٹھک، درخت بولا۔ [calm] مگر فاطمہ تو مزے سے سو چکی تھی۔

**Quiz**
1. What made the tapping sound? | ٹھک ٹھک کی آواز کس کی تھی؟ → 🌳 A tree ✅ · 🐶 A dog · 🚪 A door
2. Who came to help Fatima? | فاطمہ کی مدد کو کون آیا؟ → 👩 Ammi ✅ · 🦁 A lion · 🤖 A robot
3. What did Fatima say before sleeping? | سونے سے پہلے فاطمہ نے کیا کہا؟ → "Bismillah" ✅ · "Hello" · "Bye bye"

**New words:** dark / اندھیرا · shadow / سایہ · brave / بہادر

---

## Story 11: Moti the Little Fish | ننھی مچھلی موتی
**Zone:** Samandar · **Value:** Keeping the sea clean, kindness to creatures · **Characters:** Hassan (6, blue cap), Abbu, Moti (small orange fish)

**Illustrations**
1. Bright beach, blue sea, Hassan running ahead of Abbu.
2. Hassan munching chips, holding the empty wrapper.
3. Little orange fish caught in a plastic bag at the water's edge.
4. Abbu gently freeing Moti; she swims off with a splash.
5. Hassan holding the wrapper; a bin far away up the beach. (choice)
6. Hassan and Abbu picking up trash together with a big bag.
7. Abbu kneeling beside Hassan, both looking at the clean sea.
8. Moti leaping from a wave; Hassan waving.

**English**

*Part 1*
- S1: [excited] On Sunday, Hassan and Abbu went to the beach. [happy] The sea was big and blue, and the waves went splash, splash!
- S2: [happy] Abbu bought Hassan a packet of chips. Crunch, crunch! [playfully] When the chips were finished, Hassan held the empty wrapper.
- S3: [concerned] Near the water, Hassan saw a little orange fish. Her name was Moti. [sad] She was stuck in an old plastic bag!
- S4: [warm] Abbu gently took Moti out of the bag, and she swam away. [happy] Splash!
- S5: [thoughtful] Hassan looked at his empty wrapper. The bin was far away. [short pause] [curious] What should Hassan do?

*Choice A: Walk to the bin*
[warm] "I will put it in the bin!" Hassan walked all the way to the bin and dropped the wrapper in. [happy] Plop!

*Choice B: Drop it on the sand*
[playfully] Hassan almost dropped the wrapper on the sand. [short pause] [thoughtful] Then he remembered little Moti. "No! A fish could get stuck in this too." [warm] He walked to the bin and dropped it in. Plop!

*Part 2*
- S6: [excited] Then Hassan had an idea. "Abbu, let's pick up more trash!" Together, they filled a whole bag.
- S7: [warm] Abbu smiled. "Allah made this beautiful sea for all of us, and for the fish too. We must keep it clean."
- S8: [gasps] Splash! Moti jumped out of the water, as if she was saying goodbye. [laughs] "Bye bye, Moti!" Hassan waved.

**Urdu**

*Part 1*
- S1: [excited] اتوار کے دن حسن ابو کے ساتھ سمندر کنارے گیا۔ [happy] سمندر بڑا اور نیلا تھا، اور لہریں چھپاک، چھپاک کر رہی تھیں!
- S2: [happy] ابو نے حسن کو چپس کا ایک پیکٹ لے کر دیا۔ کرچ، کرچ! [playfully] جب چپس ختم ہو گئے تو حسن کے ہاتھ میں خالی پیکٹ رہ گیا۔
- S3: [concerned] پانی کے پاس حسن نے ایک ننھی سی نارنجی مچھلی دیکھی۔ اس کا نام موتی تھا۔ [sad] وہ ایک پرانی پلاسٹک کی تھیلی میں پھنسی ہوئی تھی!
- S4: [warm] ابو نے آہستہ سے موتی کو تھیلی سے نکالا اور وہ تیر کر چلی گئی۔ [happy] چھپاک!
- S5: [thoughtful] حسن نے اپنا خالی پیکٹ دیکھا۔ کوڑے دان بہت دور تھا۔ [short pause] [curious] حسن کو کیا کرنا چاہیے؟

*Choice A*
[warm] "میں اسے کوڑے دان میں ڈالوں گا!" حسن چلتا ہوا کوڑے دان تک گیا اور پیکٹ اندر ڈال دیا۔ [happy] ٹپ!

*Choice B*
[playfully] حسن ریت پر پیکٹ پھینکنے ہی والا تھا۔ [short pause] [thoughtful] پھر اسے ننھی موتی یاد آئی۔ "نہیں! اس میں بھی کوئی مچھلی پھنس سکتی ہے۔" [warm] وہ کوڑے دان تک گیا اور پیکٹ اندر ڈال دیا۔ ٹپ!

*Part 2*
- S6: [excited] پھر حسن کو ایک خیال آیا۔ "ابو، چلیں اور کچرا بھی اٹھاتے ہیں!" دونوں نے مل کر ایک پورا تھیلا بھر دیا۔
- S7: [warm] ابو مسکرائے۔ "اللہ تعالیٰ نے یہ خوبصورت سمندر ہم سب کے لیے بنایا ہے، اور مچھلیوں کے لیے بھی۔ ہمیں اسے صاف رکھنا ہے۔"
- S8: [gasps] چھپاک! موتی پانی سے اچھلی، جیسے خدا حافظ کہہ رہی ہو۔ [laughs] "خدا حافظ، موتی!" حسن نے ہاتھ ہلایا۔

**Quiz**
1. What color was Moti? | موتی کس رنگ کی تھی؟ → 🟠 Orange ✅ · 🟣 Purple · ⚫ Black
2. What was Moti stuck in? | موتی کس میں پھنسی تھی؟ → 🛍️ A plastic bag ✅ · 🪣 A bucket · 🎈 A balloon
3. Where did Hassan put the wrapper? | حسن نے پیکٹ کہاں ڈالا؟ → 🗑️ In the bin ✅ · 🌊 In the sea · 🏖️ On the sand

**New words:** sea / سمندر · fish / مچھلی · trash / کچرا

---

## Story 12: Kaku Crab's Special Walk | کیکڑا کاکو کی خاص چال
**Zone:** Samandar · **Value:** Don't make fun of others; everyone is special · **Characters:** Kaku (little red crab), Tara (kind turtle), Chunnu and Munnu (two little fish)

**Illustrations**
1. Little red crab beside a big rock on the beach.
2. Kaku walking sideways, little footprints zig-zagging in the sand.
3. Two small fish in a tide pool laughing; Kaku with droopy eyes.
4. Tara the turtle watching; Chunnu calling her over. (choice)
5. A big wave; a ball stuck deep in a narrow gap between rocks.
6. Kaku walking sideways into the gap, pushing the ball out.
7. Chunnu and Munnu looking sorry, fins together.
8. All four friends playing together at sunset.

**English**

*Part 1*
- S1: [warm] Kaku was a little red crab. He lived on the beach, near a big rock.
- S2: [playfully] Kaku did not walk straight like the others. He walked sideways! Tip-tap, tip-tap, this way and that way.
- S3: [sad] Two little fish, Chunnu and Munnu, laughed at him. "Ha ha! Kaku can't even walk properly!" Kaku felt very sad.
- S4: [curious] Tara the turtle saw everything. Chunnu called, "Tara, come and laugh with us!" [short pause] [curious] What should Tara do?

*Choice A: Stand with Kaku*
[warm] Tara shook her head. "No. Making fun of someone is not nice." She went to Kaku. "Kaku, will you be my friend?"

*Choice B: Laugh with them*
[giggles] Tara giggled a little. Then she saw Kaku's sad face. [softly] "Oh no. That was not nice." She went to Kaku. "Sorry, Kaku. Will you be my friend?"

*Part 2*
- S5: [gasps] Just then, a big wave came. Whoosh! Chunnu and Munnu's ball got stuck between the rocks. [sad] "Oh no! We can't reach it!"
- S6: [excited] But Kaku could! Tip-tap, tip-tap, he walked sideways into the gap and pushed the ball out. [happy] "Here you go!"
- S7: [softly] Chunnu and Munnu felt sorry. "Sorry, Kaku. We were wrong. Your walk is special!"
- S8: [warm] Allah made everyone different, and everyone special. [laughs] Now all four friends play together every day. Tip-tap, splash, splash!

**Urdu**

*Part 1*
- S1: [warm] کاکو ایک ننھا سا لال کیکڑا تھا۔ وہ سمندر کنارے ایک بڑے پتھر کے پاس رہتا تھا۔
- S2: [playfully] کاکو دوسروں کی طرح سیدھا نہیں چلتا تھا۔ وہ ٹیڑھا چلتا تھا! ٹپ ٹپ، ٹپ ٹپ، اِدھر سے اُدھر۔
- S3: [sad] دو ننھی مچھلیاں، چنو اور منو، اس پر ہنسنے لگیں۔ "ہا ہا! کاکو کو تو چلنا بھی نہیں آتا!" کاکو بہت اداس ہو گیا۔
- S4: [curious] تارا کچھوی یہ سب دیکھ رہی تھی۔ چنو نے آواز دی، "تارا، آؤ تم بھی ہنسو!" [short pause] [curious] تارا کو کیا کرنا چاہیے؟

*Choice A*
[warm] تارا نے سر ہلایا۔ "نہیں۔ کسی کا مذاق اڑانا اچھی بات نہیں۔" وہ کاکو کے پاس آئی۔ "کاکو، کیا تم میرے دوست بنو گے؟"

*Choice B*
[giggles] تارا تھوڑا سا ہنسی۔ پھر اس نے کاکو کا اداس چہرہ دیکھا۔ [softly] "اوہ! یہ اچھا نہیں تھا۔" وہ کاکو کے پاس آئی۔ "معاف کرنا کاکو۔ کیا تم میرے دوست بنو گے؟"

*Part 2*
- S5: [gasps] اتنے میں ایک بڑی لہر آئی۔ شوں! چنو منو کی گیند پتھروں کے بیچ میں پھنس گئی۔ [sad] "ارے! ہم وہاں تک نہیں پہنچ سکتے!"
- S6: [excited] مگر کاکو پہنچ سکتا تھا! ٹپ ٹپ، ٹپ ٹپ، وہ ٹیڑھا چلتا ہوا اندر گیا اور گیند باہر نکال دی۔ [happy] "یہ لو!"
- S7: [softly] چنو اور منو کو بہت افسوس ہوا۔ "معاف کرنا کاکو۔ ہم غلط تھے۔ تمہاری چال تو خاص ہے!"
- S8: [warm] اللہ تعالیٰ نے ہر ایک کو الگ بنایا ہے، اور ہر ایک کو خاص۔ [laughs] اب چاروں دوست روز مل کر کھیلتے ہیں۔ ٹپ ٹپ، چھپاک چھپاک!

**Quiz**
1. What color was Kaku? | کاکو کس رنگ کا تھا؟ → 🔴 Red ✅ · 🟢 Green · 🔵 Blue
2. How did Kaku walk? | کاکو کیسے چلتا تھا؟ → ↔️ Sideways ✅ · ⬆️ Straight · 🦘 Jumping
3. What did Kaku get out of the rocks? | کاکو نے پتھروں سے کیا نکالا؟ → ⚽ A ball ✅ · 🐚 A shell · 🎈 A balloon

**New words:** crab / کیکڑا · special / خاص · different / الگ

---

## Story 13: Zain and Nana's Boat | زین اور نانا کی کشتی
**Zone:** Samandar · **Value:** Never give up, shukr, sharing · **Characters:** Zain (7, orange life jacket), Nana (fisherman, white cap)

**Illustrations**
1. Small blue fishing boat at the harbor; Zain jumping in excitedly.
2. Boat on calm water at morning; white birds above.
3. Nana throwing a net; Zain watching.
4. Empty net, hot sun, Zain wiping his forehead.
5. Zain looking tired; Nana smiling, holding the net. (choice)
6. Heavy net full of shiny silver fish; both pulling.
7. Nana raising his hands in thanks, Zain smiling.
8. Zain and Nana giving fish to neighbors at their doors.

**English**

*Part 1*
- S1: [excited] Zain's Nana was a fisherman. Today, Zain was going with him on his little blue boat!
- S2: [calm] Nana said, "Bismillah," and the boat moved slowly over the water. [happy] White birds flew above them.
- S3: [thoughtful] Nana threw the net into the sea. They waited, and waited. [sad] But the net came up empty.
- S4: [sad] They tried again. Empty! And again. Empty! [sighs] The sun was hot, and Zain was tired.
- S5: [thoughtful] "Nana, let's go home," said Zain. Nana smiled. "Shall we try one more time?" [short pause] [curious] What should Zain say?

*Choice A: One more time*
[excited] "Yes, Nana! One more time!" Zain helped Nana throw the net, far, far into the sea.

*Choice B: Let's go home*
[sighs] "No, Nana. I'm too tired." [short pause] [thoughtful] Then Zain saw Nana, still smiling, still trying. [excited] "Okay, Nana! One more time!" Together, they threw the net far into the sea.

*Part 2*
- S6: [gasps] The net felt heavy! They pulled and pulled. [excited] It was full of shiny silver fish! Flip, flop, flip!
- S7: [happy] "Alhamdulillah!" said Nana. "See, Zain? We never give up. We try our best, and Allah gives us."
- S8: [warm] Back home, Nana and Zain shared the fish with their neighbors. [laughs] That night, everyone had a yummy dinner!

**Urdu**

*Part 1*
- S1: [excited] زین کے نانا مچھیرے تھے۔ آج زین ان کے ساتھ ان کی چھوٹی سی نیلی کشتی میں جا رہا تھا!
- S2: [calm] نانا نے "بسم اللہ" کہا اور کشتی آہستہ آہستہ پانی پر چلنے لگی۔ [happy] اوپر سفید پرندے اڑ رہے تھے۔
- S3: [thoughtful] نانا نے سمندر میں جال پھینکا۔ وہ انتظار کرتے رہے، اور کرتے رہے۔ [sad] مگر جال خالی نکلا۔
- S4: [sad] انہوں نے پھر کوشش کی۔ خالی! پھر کوشش کی۔ خالی! [sighs] دھوپ تیز تھی اور زین تھک گیا تھا۔
- S5: [thoughtful] "نانا، چلیں گھر چلتے ہیں،" زین نے کہا۔ نانا مسکرائے۔ "ایک بار اور کوشش کریں؟" [short pause] [curious] زین کو کیا کہنا چاہیے؟

*Choice A*
[excited] "جی نانا! ایک بار اور!" زین نے نانا کے ساتھ مل کر جال دور سمندر میں پھینکا۔

*Choice B*
[sighs] "نہیں نانا، میں بہت تھک گیا ہوں۔" [short pause] [thoughtful] پھر زین نے دیکھا کہ نانا اب بھی مسکرا رہے ہیں، اب بھی کوشش کر رہے ہیں۔ [excited] "اچھا نانا! ایک بار اور!" دونوں نے مل کر جال دور سمندر میں پھینکا۔

*Part 2*
- S6: [gasps] جال بہت بھاری تھا! انہوں نے کھینچا اور کھینچا۔ [excited] جال چمکتی ہوئی مچھلیوں سے بھرا ہوا تھا!
- S7: [happy] "الحمدللہ!" نانا نے کہا۔ "دیکھا زین؟ ہم ہمت نہیں ہارتے۔ ہم پوری کوشش کرتے ہیں، اور اللہ تعالیٰ دیتے ہیں۔"
- S8: [warm] گھر آ کر نانا اور زین نے پڑوسیوں کے ساتھ مچھلیاں بانٹیں۔ [laughs] اس رات سب نے مزے کا کھانا کھایا!

**Quiz**
1. What color was the boat? | کشتی کس رنگ کی تھی؟ → 🔵 Blue ✅ · 🔴 Red · 🟡 Yellow
2. What did they use to catch fish? | انہوں نے مچھلیاں کس سے پکڑیں؟ → 🕸️ A net ✅ · 🪣 A bucket · 🥄 A spoon
3. Who did they share the fish with? | انہوں نے مچھلیاں کس کے ساتھ بانٹیں؟ → 🏘️ Neighbors ✅ · 🐱 Cats · 🐦 Birds

**New words:** fisherman / مچھیرا · net / جال · try / کوشش

---

## Story 14: Maryam's Seashell | مریم کی سیپی
**Zone:** Samandar · **Value:** Giving what we love, kindness to siblings · **Characters:** Maryam (7, pink scarf), her little brother Musa (4), Ammi

**Illustrations**
1. Maryam and Musa on the sand with little piles of shells.
2. Maryam holding up a round shell glowing with rainbow colors.
3. A wave washing Musa's shells away; Musa crying.
4. Musa looking at Maryam's shell with teary eyes; Maryam thinking. (choice)
5. Musa holding the shell to his ear, eyes closed, smiling.
6. Ammi sitting with them, hand on Maryam's shoulder.
7. A new wave leaving two shiny shells on the sand.
8. Walking home at sunset, Musa holding Maryam's hand.

**English**

*Part 1*
- S1: [happy] Maryam and her little brother Musa were collecting shells at the beach. [excited] "Look, Musa! This one is white. This one is pink!"
- S2: [gasps] Then Maryam found the most beautiful shell of all. It was round, and it shined with seven colors! [whispers] "Wow!"
- S3: [sad] Just then, Musa started to cry. A wave had washed away all his shells. "My shells are gone!"
- S4: [softly] Musa looked at Maryam's shiny shell with teary eyes. [thoughtful] Maryam loved that shell so much. [short pause] [curious] What should Maryam do?

*Choice A: Give it to Musa*
[warm] Maryam held out her shiny shell. "Here, Musa. This is for you." Musa stopped crying at once.

*Choice B: Keep it*
[thoughtful] Maryam hid the shell behind her back. [short pause] [softly] But Musa was still crying, and that made her sad too. [warm] She held it out. "Here, Musa. This is for you." Musa stopped crying at once.

*Part 2*
- S5: [happy] Musa held the shell to his ear. [whispers] "Maryam Baji, I can hear the sea!" [laughs] He gave her a big hug.
- S6: [warm] Ammi saw everything. "Maryam, when we give away something we love, Allah gives us something even better."
- S7: [gasps] And guess what? A new wave came and left something on the sand. [excited] Two shiny shells! One for Maryam, and one more for Musa!
- S8: [softly] On the way home, Musa held Maryam's hand. [warm] "You are the best Baji in the whole world!"

**Urdu**

*Part 1*
- S1: [happy] مریم اور اس کا چھوٹا بھائی موسیٰ سمندر کنارے سیپیاں جمع کر رہے تھے۔ [excited] "دیکھو موسیٰ! یہ سفید ہے۔ یہ گلابی ہے!"
- S2: [gasps] پھر مریم کو سب سے پیاری سیپی ملی۔ وہ گول تھی اور اس میں سات رنگ چمک رہے تھے! [whispers] "واہ!"
- S3: [sad] اتنے میں موسیٰ رونے لگا۔ ایک لہر اس کی ساری سیپیاں بہا کر لے گئی تھی۔ "میری سیپیاں چلی گئیں!"
- S4: [softly] موسیٰ نے آنسو بھری آنکھوں سے مریم کی چمکدار سیپی کو دیکھا۔ [thoughtful] مریم کو وہ سیپی بہت پسند تھی۔ [short pause] [curious] مریم کو کیا کرنا چاہیے؟

*Choice A*
[warm] مریم نے اپنی چمکدار سیپی آگے بڑھائی۔ "یہ لو موسیٰ، یہ تمہارے لیے ہے۔" موسیٰ نے فوراً رونا بند کر دیا۔

*Choice B*
[thoughtful] مریم نے سیپی اپنی کمر کے پیچھے چھپا لی۔ [short pause] [softly] مگر موسیٰ ابھی بھی رو رہا تھا، اور اسے دیکھ کر مریم بھی اداس ہو گئی۔ [warm] اس نے سیپی آگے بڑھائی۔ "یہ لو موسیٰ، یہ تمہارے لیے ہے۔" موسیٰ نے فوراً رونا بند کر دیا۔

*Part 2*
- S5: [happy] موسیٰ نے سیپی کان سے لگائی۔ [whispers] "مریم باجی، اس میں سمندر کی آواز آ رہی ہے!" [laughs] اس نے مریم کو زور سے گلے لگا لیا۔
- S6: [warm] امی نے سب دیکھ لیا تھا۔ "مریم، جب ہم اپنی پسند کی چیز کسی کو دیتے ہیں تو اللہ تعالیٰ ہمیں اس سے بھی اچھی چیز دیتے ہیں۔"
- S7: [gasps] اور پتا ہے کیا ہوا؟ ایک نئی لہر آئی اور ریت پر کچھ چھوڑ گئی۔ [excited] دو چمکدار سیپیاں! ایک مریم کے لیے، اور ایک اور موسیٰ کے لیے!
- S8: [softly] گھر جاتے ہوئے موسیٰ نے مریم کا ہاتھ پکڑا ہوا تھا۔ [warm] "آپ دنیا کی سب سے اچھی باجی ہیں!"

**Quiz**
1. What were they collecting? | وہ کیا جمع کر رہے تھے؟ → 🐚 Shells ✅ · 🪨 Stones · 🍬 Candies
2. Why was Musa crying? | موسیٰ کیوں رو رہا تھا؟ → 🌊 A wave took his shells ✅ · 🍦 His ice cream fell · 🐶 A dog barked
3. What did Musa hear in the shell? | موسیٰ کو سیپی میں کیا سنائی دیا؟ → 🌊 The sea ✅ · 🎵 Music · 🐦 Birds

**New words:** shell / سیپی · gift / تحفہ · brother / بھائی

---

## Story 15: Hamid Holds Abbu's Hand | حامد اور ابو کا ہاتھ
**Zone:** Samandar · **Value:** Listening to parents, staying safe in water · **Characters:** Hamid (5, green shorts), Abbu, Ammi

**Illustrations**
1. Hamid's first time at the beach, toes in warm sand, sparkling sea.
2. Abbu kneeling, holding Hamid's hand, explaining.
3. Hamid splashing in tiny waves at the shore.
4. A colorful ball floating far out; Abbu and Ammi spreading a mat behind.
5. Hamid at the water's edge, looking at the ball. (choice)
6. Abbu hugging Hamid.
7. Holding hands in the water; Abbu catching the ball.
8. Hamid and Abbu playing catch on the sand at sunset.

**English**

*Part 1*
- S1: [excited] Hamid was at the beach for the very first time! [happy] The sand was warm, and the water was cool and sparkly.
- S2: [warm] Abbu said, "Hamid, the sea is big and strong. Always hold my hand in the water, okay?" [happy] "Okay, Abbu!"
- S3: [playfully] Hamid splashed in the small waves. Splash! Splash! [laughs] It was so much fun!
- S4: [curious] Then Hamid saw a big, colorful ball floating far away in the deep water. Abbu was busy helping Ammi with the mat.
- S5: [thoughtful] Hamid really wanted that ball. He could go into the deep water alone, or he could wait for Abbu. [short pause] [curious] What should Hamid do?

*Choice A: Wait for Abbu*
[calm] Hamid stopped and remembered Abbu's words. He ran back. "Abbu! There's a ball out there. Will you come with me?"

*Choice B: Go in alone*
[excited] Hamid took a few steps into the water. [gasps] Whoosh! A big wave splashed right in his face. [nervous] "Abbu said always hold his hand!" He ran back. "Abbu! Will you come with me?"

*Part 2*
- S6: [warm] Abbu hugged Hamid tight. "Shabash, Hamid! You did the right thing. Deep water is not safe for little ones alone."
- S7: [happy] Holding hands, they walked into the water together. Abbu reached out and caught the ball. [laughs] "Got it!"
- S8: [excited] Hamid and Abbu played catch on the sand until the sun went down. [softly] "Alhamdulillah," said Hamid. "Best beach day ever!"

**Urdu**

*Part 1*
- S1: [excited] حامد پہلی بار سمندر کنارے آیا تھا! [happy] ریت گرم تھی اور پانی ٹھنڈا اور چمکتا ہوا تھا۔
- S2: [warm] ابو نے کہا، "حامد، سمندر بہت بڑا اور طاقتور ہے۔ پانی میں ہمیشہ میرا ہاتھ پکڑ کر رکھنا، ٹھیک ہے؟" [happy] "جی ابو!"
- S3: [playfully] حامد چھوٹی چھوٹی لہروں میں کھیلنے لگا۔ چھپاک! چھپاک! [laughs] بہت مزہ آ رہا تھا!
- S4: [curious] پھر حامد نے گہرے پانی میں دور ایک بڑی رنگ برنگی گیند تیرتی دیکھی۔ ابو امی کے ساتھ چٹائی بچھا رہے تھے۔
- S5: [thoughtful] حامد کا دل چاہ رہا تھا کہ وہ گیند لے آئے۔ وہ اکیلا گہرے پانی میں جا سکتا تھا، یا ابو کا انتظار کر سکتا تھا۔ [short pause] [curious] حامد کو کیا کرنا چاہیے؟

*Choice A*
[calm] حامد رک گیا اور اسے ابو کی بات یاد آئی۔ وہ واپس بھاگا۔ "ابو! وہاں ایک گیند ہے۔ آپ میرے ساتھ چلیں گے؟"

*Choice B*
[excited] حامد نے پانی میں چند قدم بڑھائے۔ [gasps] شوں! ایک بڑی لہر سیدھی اس کے منہ پر آئی۔ [nervous] "ابو نے کہا تھا ہمیشہ ان کا ہاتھ پکڑ کر رکھنا!" وہ واپس بھاگا۔ "ابو! آپ میرے ساتھ چلیں گے؟"

*Part 2*
- S6: [warm] ابو نے حامد کو زور سے گلے لگایا۔ "شاباش حامد! تم نے بالکل ٹھیک کیا۔ گہرا پانی بچوں کے لیے اکیلے میں محفوظ نہیں ہوتا۔"
- S7: [happy] دونوں ہاتھ پکڑ کر پانی میں گئے۔ ابو نے ہاتھ بڑھا کر گیند پکڑ لی۔ [laughs] "مل گئی!"
- S8: [excited] حامد اور ابو شام تک ریت پر گیند سے کھیلتے رہے۔ [softly] "الحمدللہ،" حامد نے کہا۔ "آج کا دن سب سے اچھا تھا!"

**Quiz**
1. What did Abbu ask Hamid to do in the water? | ابو نے پانی میں حامد سے کیا کہا؟ → ✋ Hold his hand ✅ · 🏃 Run fast · 😴 Go to sleep
2. What did Hamid see far away? | حامد نے دور کیا دیکھا؟ → ⚽ A ball ✅ · 🚢 A ship · 🐳 A whale
3. Who caught the ball? | گیند کس نے پکڑی؟ → 👨 Abbu ✅ · 🐟 A fish · 🐦 A bird

**New words:** wave / لہر · deep / گہرا · safe / محفوظ
