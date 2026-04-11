export interface Profile {
  name: string;
  role: string;
  location: string;
  email: string;
  github: string;
  blog: string;
  bio: Record<string, string>;
  stat_years: string;
  stat_projects: string;
  stat_langs: string;
}

export interface Project {
  id: number;
  title: string;
  description: Record<string, string>;
  tech: string[];
  github: string;
  live?: string;
  featured: boolean;
}

export interface Skill {
  id: number;
  name: string;
  level: number;
  category: string;
}
