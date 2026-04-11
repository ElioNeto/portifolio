import { Routes } from '@angular/router';
import { authGuard } from './core/guards/auth.guard';

export const routes: Routes = [
  {
    path: '',
    loadComponent: () => import('./features/home/home.component').then(m => m.HomeComponent)
  },
  {
    path: 'admin',
    children: [
      {
        path: 'login',
        loadComponent: () => import('./features/admin/login/login.component').then(m => m.LoginComponent)
      },
      {
        path: '',
        canActivate: [authGuard],
        loadComponent: () => import('./features/admin/dashboard/dashboard.component').then(m => m.DashboardComponent),
        children: [
          { path: 'profile', loadComponent: () => import('./features/admin/profile/profile.component').then(m => m.ProfileAdminComponent) },
          { path: 'projects', loadComponent: () => import('./features/admin/projects/projects.component').then(m => m.ProjectsAdminComponent) },
          { path: 'skills', loadComponent: () => import('./features/admin/skills/skills.component').then(m => m.SkillsAdminComponent) },
          { path: '', redirectTo: 'profile', pathMatch: 'full' }
        ]
      }
    ]
  },
  { path: '**', redirectTo: '' }
];
