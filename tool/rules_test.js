// Usage (after `firebase login`):  node tool/rules_test.js firestore.rules
// Runs security-rule test cases against firestore.rules using the Firebase Rules "test" API.
// Nothing is read from or written to the real database.
const fs = require('fs'), path = require('path'), os = require('os');
const token = JSON.parse(fs.readFileSync(path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json'), 'utf8')).tokens.access_token;
const src = fs.readFileSync(process.argv[2], 'utf8');
const D = '/databases/(default)/documents';
const NOW = '2026-11-10T20:00:00Z';

const student = { uid: 'stu1', token: { email: 'amina@alustudent.com', email_verified: true } };
const other = { uid: 'stu2', token: { email: 'kwame@alustudent.com', email_verified: true } };
const unverified = { uid: 'stu3', token: { email: 'new@alustudent.com', email_verified: false } };
const gmail = { uid: 'g1', token: { email: 'someone@gmail.com', email_verified: true } };
const staff = { uid: 'staff1', token: { email: 'staff@alueducation.com', email_verified: false } };

const content = { title: 'Water shortage', description: 'No water in block B since morning', category: 'water', location: 'Block B', urgency: 'high', photoUrl: null };
const incident = { ...content, status: 'submitted', isAnonymous: false, reporterId: 'stu1', reporterName: 'Amina', createdAt: NOW, updatedAt: NOW };
const anon = { ...content, status: 'submitted', isAnonymous: true, createdAt: NOW, updatedAt: NOW };

const mk = (fn, p, val) => ({ function: fn, args: [{ exactValue: D + p }], result: { value: val } });
const staffMocks = [mk('exists', '/users/staff1', true), mk('get', '/users/staff1', { data: { role: 'staff' } })];
const roleMocks = (uid, role) => [mk('exists', '/users/' + uid, true), mk('get', '/users/' + uid, { data: { role } })];
const ownerMocks = (uid) => [
  mk('exists', '/incidents/i1/private/owner', true),
  mk('get', '/incidents/i1/private/owner', { data: { reporterId: uid } }),
  mk('getAfter', '/incidents/i1/private/owner', { data: { reporterId: uid } }),
];

const cases = [
  ['Student creates named report (own id)', 'ALLOW', { auth: student, path: '/incidents/i1', method: 'create', data: incident }, ownerMocks('stu1')],
  ['Student creates anonymous report, no reporter fields', 'ALLOW', { auth: student, path: '/incidents/i1', method: 'create', data: anon }, ownerMocks('stu1')],
  ['Anonymous report that still leaks reporterId', 'DENY', { auth: student, path: '/incidents/i1', method: 'create', data: { ...anon, reporterId: 'stu1' } }, ownerMocks('stu1')],
  ['Student creates report as someone else', 'DENY', { auth: student, path: '/incidents/i1', method: 'create', data: { ...incident, reporterId: 'stu2' } }, ownerMocks('stu1')],
  ['Student creates report already "resolved"', 'DENY', { auth: student, path: '/incidents/i1', method: 'create', data: { ...incident, status: 'resolved' } }, ownerMocks('stu1')],
  ['Unverified email creates report', 'DENY', { auth: unverified, path: '/incidents/i1', method: 'create', data: { ...incident, reporterId: 'stu3' } }, ownerMocks('stu3')],
  ['Photo URL from another site', 'DENY', { auth: student, path: '/incidents/i1', method: 'create', data: { ...incident, photoUrl: 'https://evil.example.com/x.jpg' } }, ownerMocks('stu1')],
  ['Signed-out user reads reports', 'DENY', { path: '/incidents/i1', method: 'get' }, []],
  ['Non-ALU (gmail) user reads reports', 'DENY', { auth: gmail, path: '/incidents/i1', method: 'get' }, roleMocks('g1', 'student')],
  ['Student reads reports', 'ALLOW', { auth: student, path: '/incidents/i1', method: 'get' }, []],
  ['Student changes status of own report', 'DENY', { auth: student, path: '/incidents/i1', method: 'update', data: { ...incident, status: 'resolved' } }, ownerMocks('stu1')],
  ['Student edits own report while submitted', 'ALLOW', { auth: student, path: '/incidents/i1', method: 'update', data: { ...incident, title: 'No water at all' } }, ownerMocks('stu1')],
  ["Student edits someone else's report", 'DENY', { auth: other, path: '/incidents/i1', method: 'update', data: { ...incident, title: 'hacked' } }, [...ownerMocks('stu1'), ...roleMocks('stu2', 'student')]],
  ['Staff updates status with note', 'ALLOW', { auth: staff, path: '/incidents/i1', method: 'update', data: { ...incident, status: 'in_progress', lastNote: 'Plumber assigned' } }, [...staffMocks, ...ownerMocks('stu1')]],
  ['Staff edits report title', 'DENY', { auth: staff, path: '/incidents/i1', method: 'update', data: { ...incident, title: 'changed' } }, [...staffMocks, ...ownerMocks('stu1')]],
  ['Student signs up with role "staff"', 'DENY', { auth: student, path: '/users/stu1', method: 'create', data: { name: 'Amina', email: 'amina@alustudent.com', role: 'staff', createdAt: NOW } }, []],
  ['Student signs up with role "student"', 'ALLOW', { auth: student, path: '/users/stu1', method: 'create', data: { name: 'Amina', email: 'amina@alustudent.com', role: 'student', createdAt: NOW } }, []],
  ['Student promotes self to staff (update role)', 'DENY', { auth: student, path: '/users/stu1', method: 'update', data: { name: 'Amina', email: 'amina@alustudent.com', role: 'staff', createdAt: NOW }, existing: { name: 'Amina', email: 'amina@alustudent.com', role: 'student', createdAt: NOW } }, []],
  ["Student reads another student's profile", 'DENY', { auth: other, path: '/users/stu1', method: 'get' }, roleMocks('stu2', 'student')],
  ["Student reads owner record of someone else's report", 'DENY', { auth: other, path: '/incidents/i1/private/owner', method: 'get' }, roleMocks('stu2', 'student')],
  ['Staff reads owner record', 'ALLOW', { auth: staff, path: '/incidents/i1/private/owner', method: 'get' }, staffMocks],
  ['Student writes status history', 'DENY', { auth: student, path: '/incidents/i1/statusHistory/h1', method: 'create', data: { status: 'resolved', note: null, changedBy: 'stu1', changedAt: NOW } }, [mk('getAfter', '/incidents/i1', { data: { status: 'resolved' } })]],
  ['Staff writes matching status history', 'ALLOW', { auth: staff, path: '/incidents/i1/statusHistory/h1', method: 'create', data: { status: 'in_progress', note: 'Plumber assigned', changedBy: 'staff1', changedAt: NOW } }, [...staffMocks, mk('getAfter', '/incidents/i1', { data: { status: 'in_progress' } })]],
];

const ownerExisting = { reporterId: 'stu1', reporterName: 'Amina' };
const testCases = cases.map(([, exp, req, mocks]) => {
  const tc = { expectation: exp, request: { path: D + req.path, method: req.method, time: NOW }, functionMocks: mocks };
  if (req.auth) tc.request.auth = { uid: req.auth.uid, token: req.auth.token };
  if (req.data) tc.request.resource = { data: req.data };
  if (req.method !== 'create') {
    tc.resource = { data: req.existing || (req.path.endsWith('/owner') ? ownerExisting : req.path.startsWith('/users') ? { name: 'Amina', email: 'amina@alustudent.com', role: 'student', createdAt: NOW } : incident) };
  }
  return tc;
});

fetch('https://firebaserules.googleapis.com/v1/projects/tatua-campus:test', {
  method: 'POST',
  headers: { Authorization: 'Bearer ' + token, 'Content-Type': 'application/json', 'x-goog-user-project': 'tatua-campus' },
  body: JSON.stringify({ source: { files: [{ name: 'firestore.rules', content: src }] }, testSuite: { testCases } }),
}).then(async (r) => {
  const j = await r.json();
  if (j.error) { console.log('API error', JSON.stringify(j.error).slice(0, 1500)); return; }
  if (j.issues) console.log('issues', JSON.stringify(j.issues).slice(0, 800));
  let pass = 0;
  j.testResults.forEach((res, i) => {
    const ok = res.state === 'SUCCESS';
    pass += ok;
    console.log((ok ? 'PASS' : 'FAIL') + '  expect ' + cases[i][1].padEnd(5) + '  ' + cases[i][0] + (ok ? '' : '\n      ' + JSON.stringify(res.debugMessages || res.errorPosition || res).slice(0, 400)));
  });
  console.log(`\n${pass}/${cases.length} passed`);
});
