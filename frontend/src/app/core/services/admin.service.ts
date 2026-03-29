import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../environments/environment';
import { Profile, Project, Skill } from '../models/portfolio.models';

@Injectable({ providedIn: 'root' })
export class AdminService {
  private readonly http = inject(HttpClient);
  private readonly base = environment.apiUrl;

  // Projects
  createProject(p: Omit<Project, 'id'>) {
    return this.http.post<Project>(`${this.base}/api/admin/projects`, p);
  }
  updateProject(p: Project) {
    return this.http.put<Project>(`${this.base}/api/admin/projects/${p.id}`, p);
  }
  deleteProject(id: number) {
    return this.http.delete(`${this.base}/api/admin/projects/${id}`);
  }

  // Skills
  createSkill(s: Omit<Skill, 'id'>) {
    return this.http.post<Skill>(`${this.base}/api/admin/skills`, s);
  }
  updateSkill(s: Skill) {
    return this.http.put<Skill>(`${this.base}/api/admin/skills/${s.id}`, s);
  }
  deleteSkill(id: number) {
    return this.http.delete(`${this.base}/api/admin/skills/${id}`);
  }

  // Profile
  updateProfile(p: Profile) {
    return this.http.put<Profile>(`${this.base}/api/admin/profile`, p);
  }
}
