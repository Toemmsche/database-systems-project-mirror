import { ComponentFixture, TestBed } from '@angular/core/testing';

import { KandidatenComponent } from './kandidaten.component';

describe('KandidatenComponent', () => {
  let component: KandidatenComponent;
  let fixture: ComponentFixture<KandidatenComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ KandidatenComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(KandidatenComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
