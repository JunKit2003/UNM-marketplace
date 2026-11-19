import sharp from 'sharp';

/** A real PNG of the given size, for upload tests. */
export function pngBuffer(width = 64, height = 48, color = { r: 124, g: 92, b: 255 }) {
  return sharp({ create: { width, height, channels: 3, background: color } }).png().toBuffer();
}

export const notAnImage = Buffer.from('this is plain text pretending to be a photo');

export const signupBody = (n = 1, extra = {}) => ({
  firstName: 'Amy',
  lastName: `Tester${n}`,
  username: `amy${n}`,
  email: `amy${n}@nottingham.edu.my`,
  phone: '+60 12-345 6789',
  password: 'correct-horse-1',
  ...extra,
});
