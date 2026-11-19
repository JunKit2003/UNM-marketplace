const RULES = [
  [/\b(available|still)\b/i, (t) => `Hi! Yes, the ${t} is still available 🙂`],
  [/\b(price|discount|cheaper|lower|nego\w*)\b/i, () => 'I can do a little off if you collect this week. What did you have in mind?'],
  [/\b(meet|where|collect|pickup)\b|\bpick up\b/i, () => "I'm usually around the Trent Building or the library. Does tomorrow afternoon work?"],
];

/** A friendly, listing-aware reply for the demo sellers. */
export function pickReply(listingTitle, body) {
  for (const [re, reply] of RULES) if (re.test(body)) return reply(listingTitle);
  return `Thanks for the message! Happy to answer anything about the ${listingTitle}.`;
}
