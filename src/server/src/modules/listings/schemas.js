import { z } from 'zod';

export const CONDITIONS = ['Brand new', 'Like new', 'Lightly used', 'Well used', 'Heavily used'];
export const SORTS = ['newest', 'price_asc', 'price_desc'];
export const PAGE_SIZE = 24;
const PRICE_MESSAGE = 'Enter a price from 0 to 1,000,000 with up to 2 decimals, e.g. 45 or 12.50.';

/** Accepts "45", "12.50", 45, 12.5. Rejects "1,200", negatives, 3+ decimals, > 1,000,000. */
export const price = z
  .union([z.string(), z.number()], { error: PRICE_MESSAGE })
  .transform((v) => String(v).trim())
  .refine((v) => /^\d{1,7}(\.\d{1,2})?$/.test(v) && Number(v) <= 1_000_000, PRICE_MESSAGE)
  .transform(Number);

const title = z.string().trim().min(3, 'Give it a title of at least 3 characters.').max(80, 'Keep the title under 80 characters.');
const description = z.string().trim().min(1, 'Add a short description.').max(2000, 'Keep the description under 2,000 characters.');
const categorySlug = z.string().trim().min(1, 'Pick a category.');
const condition = z.enum(CONDITIONS, { error: 'Pick a condition.' });

export const createListingSchema = z.object({ title, description, price, categorySlug, condition });

export const updateListingSchema = z
  .object({
    title: title.optional(),
    description: description.optional(),
    price: price.optional(),
    categorySlug: categorySlug.optional(),
    condition: condition.optional(),
    status: z.enum(['active', 'sold']).optional(),
  })
  .strict();

const optionalNumber = z
  .string()
  .regex(/^\d+(\.\d{1,2})?$/, 'Must be a number.')
  .transform(Number)
  .optional();

export const browseQuerySchema = z.object({
  q: z.string().trim().max(100).optional(),
  category: z.string().trim().max(40).optional(),
  condition: z.enum(CONDITIONS).optional(),
  min: optionalNumber,
  max: optionalNumber,
  sort: z.enum(SORTS).default('newest'),
  page: z.coerce.number().int().min(1).max(10_000).default(1),
  status: z.enum(['active', 'sold', 'all']).default('active'),
});

export const myListingsQuerySchema = z.object({ status: z.enum(['active', 'sold']).optional() });

export const reorderSchema = z.object({ imageIds: z.array(z.number().int().positive()).min(1).max(6) });
