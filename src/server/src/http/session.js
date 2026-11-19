/** Start a fresh session for this user (prevents session fixation). */
export function startSession(req, user) {
  return new Promise((resolve, reject) => {
    req.session.regenerate((err) => {
      if (err) return reject(err);
      req.session.userId = user.id;
      req.session.isGuest = Boolean(user.is_guest);
      req.session.save((e) => (e ? reject(e) : resolve()));
    });
  });
}

export function endSession(req) {
  return new Promise((resolve) => {
    if (!req.session) return resolve();
    req.session.destroy(() => resolve());
  });
}
