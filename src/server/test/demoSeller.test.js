import { describe, expect, it } from 'vitest';
import { pickReply } from '../src/modules/chat/demoSeller.js';

describe('pickReply', () => {
  it.each([
    ['Is this still available?', 'Hi! Yes, the Desk lamp is still available 🙂'],
    ['Any discount?', 'I can do a little off if you collect this week. What did you have in mind?'],
    ['Can you go LOWER on price', 'I can do a little off if you collect this week. What did you have in mind?'],
    ['Where can we meet?', "I'm usually around the Trent Building or the library. Does tomorrow afternoon work?"],
    ['Can I pick up tonight', "I'm usually around the Trent Building or the library. Does tomorrow afternoon work?"],
    ['hello there', 'Thanks for the message! Happy to answer anything about the Desk lamp.'],
  ])('%s', (body, expected) => {
    expect(pickReply('Desk lamp', body)).toBe(expected);
  });
});
