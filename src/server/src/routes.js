import { registerAuth } from './modules/auth/routes.js';
import { registerMe } from './modules/me/routes.js';

/** Every feature router, in registration order. */
export const routes = [registerAuth, registerMe];
