export interface Profile {
  name: string;
  role: string;
  location: string;
  email: string;
  github: string;
  blog: string;
  bio: Record<string, string>;
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
  name: string;
  level: number;
  category: string;
}
