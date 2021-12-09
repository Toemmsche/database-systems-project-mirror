import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SitzverteilungComponent } from './sitzverteilung.component';

describe('SitzverteilungComponent', () => {
  let component: SitzverteilungComponent;
  let fixture: ComponentFixture<SitzverteilungComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ SitzverteilungComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(SitzverteilungComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
