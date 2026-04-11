import { Component, HostListener, signal } from '@angular/core';

interface NavLink {
  anchor: string;
  label: string;
}

@Component({
  selector: 'app-navbar',
  standalone: true,
  templateUrl: './navbar.component.html',
  styleUrls: ['./navbar.component.scss']
})
export class NavbarComponent {
  scrolled = signal(false);

  navLinks: NavLink[] = [
    { anchor: '#about', label: 'Sobre' },
    { anchor: '#projects', label: 'Projectos' },
    { anchor: '#skills', label: 'Skills' },
    { anchor: '#contact', label: 'Contacto' },
  ];

  apexLink = 'https://apexstore.elioneto.dev/dashboard';

  @HostListener('window:scroll')
  onScroll(): void {
    this.scrolled.set(window.scrollY > 50);
  }
}
