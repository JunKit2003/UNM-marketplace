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

export const listingFields = (extra = {}) => ({
  title: 'Desk lamp',
  description: 'Warm white LED desk lamp, three brightness levels.',
  price: '45',
  categorySlug: 'home-garden',
  condition: 'Like new',
  ...extra,
});

/** POST /api/listings as multipart with `photos` PNGs. */
export async function postListing(a, extra = {}, photoCount = 1) {
  let req = a.post('/api/listings');
  for (const [k, v] of Object.entries(listingFields(extra))) req = req.field(k, v);
  for (let i = 0; i < photoCount; i++) {
    req = req.attach('photos', await pngBuffer(40 + i, 30), `p${i}.png`);
  }
  return req;
}
