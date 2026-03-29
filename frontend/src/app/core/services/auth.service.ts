import { Injectable, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { tap, catchError, EMPTY } from 'rxjs';
import { environment } from '../../../environments/environment';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly http = inject(HttpClient);
  private readonly router = inject(Router);
  private readonly base = environment.apiUrl;

  readonly isAuthenticated = signal(!!this.getToken());

  private getToken(): string | null {
    return sessionStorage.getItem('access_token');
  }

  getAccessToken(): string | null {
    return this.getToken();
  }

  login(password: string) {
    return this.http
      .post<{ access_token: string }>(`${this.base}/api/auth/login`, { password }, { withCredentials: true })
      .pipe(
        tap(({ access_token }) => {
          sessionStorage.setItem('access_token', access_token);
          this.isAuthenticated.set(true);
        })
      );
  }

  refresh() {
    return this.http
      .post<{ access_token: string }>(`${this.base}/api/auth/refresh`, {}, { withCredentials: true })
      .pipe(
        tap(({ access_token }) => {
          sessionStorage.setItem('access_token', access_token);
          this.isAuthenticated.set(true);
        }),
        catchError(() => {
          this.clearSession();
          return EMPTY;
        })
      );
  }

  logout() {
    this.http.post(`${this.base}/api/auth/logout`, {}, { withCredentials: true }).subscribe();
    this.clearSession();
    this.router.navigate(['/admin/login']);
  }

  sendOTP(purpose: string) {
    return this.http.post(`${this.base}/api/auth/otp/send?purpose=${purpose}`, {}, { withCredentials: true });
  }

  validateOTP(purpose: string, code: string) {
    return this.http.post(`${this.base}/api/auth/otp/validate`, { purpose, code }, { withCredentials: true });
  }

  private clearSession() {
    sessionStorage.removeItem('access_token');
    this.isAuthenticated.set(false);
  }
}
