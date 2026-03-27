import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, shareReplay } from 'rxjs';
import { environment } from '../../environments/environment';
import { Profile, Project, Skill } from '../models/portfolio.models';

@Injectable({ providedIn: 'root' })
export class PortfolioService {
  private readonly http = inject(HttpClient);
  private readonly base = environment.apiUrl;

  getProfile(): Observable<Profile> {
    return this.http.get<Profile>(`${this.base}/api/profile`).pipe(shareReplay(1));
  }

  getProjects(): Observable<Project[]> {
    return this.http.get<Project[]>(`${this.base}/api/projects`).pipe(shareReplay(1));
  }

  getSkills(): Observable<Skill[]> {
    return this.http.get<Skill[]>(`${this.base}/api/skills`).pipe(shareReplay(1));
  }
}
