import { registerAuth } from './modules/auth/routes.js';
import { registerListings } from './modules/listings/routes.js';
import { registerMe } from './modules/me/routes.js';
import { registerSaved } from './modules/saved/routes.js';

/** Every feature router, in registration order. */
export const routes = [registerAuth, registerMe, registerListings, registerSaved];
