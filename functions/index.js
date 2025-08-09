const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.resetUserPassword = functions.https.onCall(async (data, context) => {
    // 1. Periksa apakah pemanggil adalah admin (opsional tapi sangat direkomendasikan)
    // Anda bisa menyimpan role admin di Firestore user document
    // dan memeriksanya di sini menggunakan context.auth.uid
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'Hanya pengguna terautentikasi yang dapat memanggil fungsi ini.'
        );
    }

    // Contoh: Periksa role admin dari Firestore
    const callerUid = context.auth.uid;
    const callerUserDoc = await admin.firestore().collection('users').doc(callerUid).get();
    const callerUserType = callerUserDoc.data()?.userType;

    if (callerUserType !== 'admin' && callerUserType !== 'sekretaris') { // Sesuaikan role admin Anda
        throw new functions.https.HttpsError(
            'permission-denied',
            'Anda tidak memiliki izin untuk mereset password pengguna lain.'
        );
    }

    // 2. Ambil data dari permintaan
    const uidToReset = data.uid;
    const newPassword = data.newPassword;

    // Validasi input
    if (!uidToReset || typeof uidToReset !== 'string' || !newPassword || typeof newPassword !== 'string' || newPassword.length < 6) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'UID dan password baru (minimal 6 karakter) diperlukan.'
        );
    }

    try {
        // 3. Reset password menggunakan Firebase Admin SDK
        await admin.auth().updateUser(uidToReset, {
            password: newPassword,
        });

        return { status: 'success', message: `Password untuk user ${uidToReset} berhasil direset.` };
    } catch (error) {
        console.error('Error resetting password:', error);
        throw new functions.https.HttpsError(
            'internal',
            'Gagal mereset password: ' + error.message
        );
    }
});

// Contoh Cloud Function untuk deleteUserAccount (jika ingin menghapus akun Firebase juga)
exports.deleteUserAccount = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'Hanya pengguna terautentikasi yang dapat memanggil fungsi ini.'
        );
    }

    const callerUid = context.auth.uid;
    const callerUserDoc = await admin.firestore().collection('users').doc(callerUid).get();
    const callerUserType = callerUserDoc.data()?.userType;

    if (callerUserType !== 'admin' && callerUserType !== 'sekretaris') {
        throw new functions.https.HttpsError(
            'permission-denied',
            'Anda tidak memiliki izin untuk menghapus pengguna lain.'
        );
    }

    const uidToDelete = data.uid;

    if (!uidToDelete || typeof uidToDelete !== 'string') {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'UID pengguna diperlukan.'
        );
    }

    try {
        await admin.auth().deleteUser(uidToDelete);
        // Opsional: Hapus juga dokumen Firestore jika belum dilakukan di klien
        // await admin.firestore().collection('users').doc(uidToDelete).delete();
        return { status: 'success', message: `Akun user ${uidToDelete} berhasil dihapus.` };
    } catch (error) {
        console.error('Error deleting user account:', error);
        throw new functions.https.HttpsError(
            'internal',
            'Gagal menghapus akun pengguna: ' + error.message
        );
    }
});