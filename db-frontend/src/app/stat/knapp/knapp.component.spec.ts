import { ComponentFixture, TestBed } from '@angular/core/testing';

import { KnappComponent } from './knapp.component';

describe('KnappComponent', () => {
  let component: KnappComponent;
  let fixture: ComponentFixture<KnappComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ KnappComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(KnappComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
