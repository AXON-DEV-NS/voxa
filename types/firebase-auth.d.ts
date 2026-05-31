declare module 'firebase/auth' {
  import { FirebaseApp } from 'firebase/app';

  export interface User {
    uid: string;
    email: string | null;
    displayName: string | null;
    photoURL: string | null;
    getIdToken: (forceRefresh?: boolean) => Promise<string>;
  }

  export interface UserCredential {
    user: User;
  }

  export interface Auth {
    currentUser: User | null;
  }

  export function getAuth(app?: FirebaseApp): Auth;
  export class GoogleAuthProvider {
    constructor();
    addScope(scope: string): void;
    static credentialFromResult(user: any): any;
  }
  export function signInWithPopup(auth: Auth, provider: GoogleAuthProvider): Promise<UserCredential>;
  export function signInWithEmailAndPassword(auth: Auth, email: string, password: string): Promise<UserCredential>;
  export function createUserWithEmailAndPassword(auth: Auth, email: string, password: string): Promise<UserCredential>;
  export function signOut(auth: Auth): Promise<void>;
  export function onAuthStateChanged(auth: Auth, nextOrObserver: (user: User | null) => void): () => void;
}
